#!/bin/bash

# Vérification des arguments
if [ $# -ne 2 ]; then
    echo "Utilisation: $0 config_file [daily|weekly|monthly]"
    exit 1
fi

CONFIG_FILE=$1
INTERVAL=$2

# Charger la configuration
source "$CONFIG_FILE"

# Définir LOGFILE et ERROR_LOG en utilisant BACKUP_DIR du fichier de configuration
LOGFILE="$BACKUP_DIR/backup_$INTERVAL.log"
ERROR_LOG="$BACKUP_DIR/backup_$INTERVAL.stderr"  # Fichier de log d'erreur
LOCKFILE="$BACKUP_DIR/backup.lock"

# Vérification de l'intervalle
if ! [[ "$INTERVAL" =~ ^(daily|weekly|monthly)$ ]]; then
    echo "Intervalle incorrect. Utilisation: $0 config_file [daily|weekly|monthly]"
    exit 1
fi

# Définir le nombre max de sauvegardes en fonction de l'intervalle choisi
if [ "$INTERVAL" == "daily" ]; then
    MAX_BACKUPS=$MAX_BACKUPS_DAILY
elif [ "$INTERVAL" == "weekly" ]; then
    MAX_BACKUPS=$MAX_BACKUPS_WEEKLY
elif [ "$INTERVAL" == "monthly" ]; then
    MAX_BACKUPS=$MAX_BACKUPS_MONTHLY
fi

# Arguments rsync
RSYNC_LONG_ARGS="--stats --delete --numeric-ids --delete-excluded --exclude=.gvfs --exclude=*/repe_out/* --exclude=*repe_out* --exclude=*.vdi --exclude=*/.recycle/* -i --bwlimit=50000"
SSH_ARGS="-x -p 22 -i /var/services/homes/astral/.ssh/backup_key.key -o Compression=no -o BatchMode=yes -o StrictHostKeyChecking=no"
RSYNC_PATH="/usr/bin/rsync"

# Fonction pour logger dans un fichier
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$LOGFILE"
}

# Assurez-vous que les répertoires pour LOGFILE et LOCKFILE existent
mkdir -p "$(dirname "$LOGFILE")"
mkdir -p "$(dirname "$LOCKFILE")"

# Vérifier le fichier de verrouillage
if [ -f "$LOCKFILE" ]; then
    log "Le script de sauvegarde est déjà en cours d'exécution. Sortie."
    exit 1
else
    touch "$LOCKFILE"
fi

# Nettoyer le fichier de verrouillage lors de la sortie
trap 'rm -f "$LOCKFILE"; exit' INT TERM EXIT

# Commencer le logging
log "Début de la sauvegarde."

# Rotation des sauvegardes
log "Rotation des sauvegardes..."
# Supprimez le répertoire le plus ancien
if [ -d "$BACKUP_DIR/${INTERVAL}.${MAX_BACKUPS}" ]; then
    cmd="rm -rf $BACKUP_DIR/${INTERVAL}.${MAX_BACKUPS}"
    log "$cmd"
    eval $cmd
    log "Le répertoire ${INTERVAL}.${MAX_BACKUPS} a été supprimé."
fi

# Décalez les anciens répertoires
for ((i=MAX_BACKUPS-1; i>=1; i--)); do
    if [ -d "$BACKUP_DIR/${INTERVAL}.$i" ]; then
        cmd="mv $BACKUP_DIR/${INTERVAL}.$i $BACKUP_DIR/${INTERVAL}.$((i+1))"
        log "$cmd"
        eval $cmd
        log "Le répertoire ${INTERVAL}.$i a été renommé en ${INTERVAL}.$((i+1))."
    fi
done

# Renommez le répertoire le plus récent s'il existe
if [ -d "$BACKUP_DIR/${INTERVAL}.0" ]; then
    cmd="mv $BACKUP_DIR/${INTERVAL}.0 $BACKUP_DIR/${INTERVAL}.1"
    log "$cmd"
    eval $cmd
    log "Le répertoire ${INTERVAL}.0 a été renommé en ${INTERVAL}.1."
fi

# Sauvegarde avec Rsync pour chaque répertoire
for DIR in "${DIRECTORIES[@]}"; do
    log "Traitement du répertoire $DIR..."

    # Supprimez le slash initial de DIR si présent
    DIR="${DIR#/}"
    DEST_DIR="$BACKUP_DIR/${INTERVAL}.0/$DIR"

    # Assurez-vous que le chemin se termine par un slash '/'
    REMOTE_DIR="$REMOTE_HOST:/$DIR/"

    # Créer le répertoire de destination s'il n'existe pas
    mkdir -p "$DEST_DIR"

    # Construire le chemin --link-dest
    if [ "$INTERVAL" == "daily" ]; then
        LINK_DEST="$BACKUP_DIR/${INTERVAL}.1/$DIR"  # Utilisez le chemin complet pour daily
    else
        LINK_DEST="$BACKUP_DIR/daily.0/$DIR"  # Utilisez le dernier backup daily pour weekly et monthly
    fi
    LINK_DEST="${LINK_DEST%/}"  # Supprime le slash final si présent

    # Construire la commande rsync
    RSYNC_CMD="rsync -a $RSYNC_LONG_ARGS --rsh=\"ssh $SSH_ARGS\" --rsync-path=\"$RSYNC_PATH\" \"$REMOTE_DIR\" \"$DEST_DIR\""

    # Ajouter --link-dest à la commande rsync si le répertoire existe
    if [ -d "$LINK_DEST" ]; then
        RSYNC_CMD+=" --link-dest=\"$LINK_DEST\""
    else
        log "Répertoire pour --link-dest n'existe pas: $LINK_DEST"
    fi

    log "Début de la sauvegarde avec Rsync pour $DIR..."
    log "$RSYNC_CMD"
    eval $RSYNC_CMD >> "$LOGFILE" 2>> "$ERROR_LOG"
    RSYNC_EXIT_CODE=$?

    # Vérifier si rsync a réussi
    if [ $RSYNC_EXIT_CODE -ne 0 ]; then
        log "La sauvegarde rsync a échoué pour $DIR."
        echo "Erreur lors de l'exécution de rsync. Code de sortie: $RSYNC_EXIT_CODE" >> "$ERROR_LOG"
        exit 1
    else
        log "La sauvegarde rsync a réussi pour $DIR."
    fi
done

log "Sauvegarde terminée."

# Supprimer le fichier de verrouillage à la fin
rm -f "$LOCKFILE"



