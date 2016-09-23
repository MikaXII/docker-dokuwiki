#!/bin/bash

function log {
  echo $*
  echo $* >> $LOG
}

function err {
  echo "ERROR : $*"
  echo $* >> $ERR
}

# Copie des images dans $SOURCE, puis dans le bon repertoire de dokuwiki
git clone $WIKI_SOURCE $SOURCE
cp -R $SOURCE/wiki/images $MEDIA
# On vide $SOURCE qui n'a plus d'utilite et servira pour le wiki
rm -rf $SOURCE
# Récupération du wiki en cours + changement des droits sur dokuwiki pou reviter des trous de securite
git clone $WIKI_SOURCE $SOURCE

#chown -R www-data:www-data $SOURCE

# test existance SOURCE et DEST
if [ ! -d $SOURCE ] || [ ! -d $DEST ]; then
  echo "$SOURCE ou $DEST manquant" >&2
  exit 1
fi

echo "SOURCE et DEST presents, let's go ..."
# Pour chaque fichier

for file in $(ls $SOURCE/*.md); do
  shortFileName=$(basename $file)
  languageMAJ=$(echo $file | egrep -o '\([A-Z][A-Z]\)' | egrep -o '[A-Z][A-Z]')
  languageMIN=$(echo $languageMAJ | tr '[:upper:]' '[:lower:]')
  # Extension en .txt, en minuscules, replace spaces by -, remove language suffix -(EN), 
  wikiFileName="$(basename $shortFileName .md | tr '[:upper:]' '[:lower:]' | sed "s/-($languageMIN)//g" | sed "s/[ ]/-/g").txt"
  
  if [ ""$languageMAJ"" == "" ]; then
    err "$(date) $shortFileName : pas de langue disponible -> on zappe"
    continue
  fi
  
  log "Migration de $shortFileName vers $DEST/$languageMIN/$wikiFileName"
  
  # On verifie que le repertoire de langue existe
  mkdir -p "$DEST/$languageMIN"
  # Copie dans son repertoire de destination en nom ecourté
  # cp $file $DEST/$languageMIN/$wikiFileName
  pandoc --from markdown_github --to dokuwiki $file --output $DEST/$languageMIN/$wikiFileName
  if [ $? -ne 0 ] ; then
    err "  /!\ $shortFileName : erreur à la conversion"
    continue
  fi
  #chown -R www-data:www-data $DEST/$languageMIN/$wikiFileName
  
  # Echanger [[blabla|TOTO]] en [[toto|blabla]] avec toto converti en minuscule
  # Virer les suffixes -(xx) dans les liens car le nom de fichier a été basculé en minuscule. Ex : "[[shaders-configuration-(en)|Shaders configuration]]" en "[[shaders-configuration|Shaders configuration]]"
  # Virer le suffixe de langue en majuscule
  # ne garder que le bluetooth-pair.jpg et l'enrober pour dokuwiki dans [[https://github.com/digitalLumberjack/recalbox-os/blob/master/wiki/images/bluetooth-pair.jpg|{{https://github.com/digitalLumberjack/recalbox-os/blob/master/wiki/images/bluetooth-pair-350px.jpg}}]] => exemple de lien d'image
  sed \
      -e 's/\[\[\([[:alnum:] ()\/\:\.\-]*\)|\([[:alnum:] ()\/\:\.\-]*\)\]\]/\[\[\L\2\E|\1\]\]/g' \
      -e 's/[\-]\?([a-zA-Z]\{2\})|/|/g' \
      -e 's+\[\[\(http[s]\?\:\/\/[[:alnum:]\/\.\-]*\)\/\([[:alnum:]\.\-]*\)\(|\){{\([[:alnum:]\:\/\.\-]*\)}}\]\]+{{:images:\2\?direct\&350}}+g' \
      -i $DEST/$languageMIN/$wikiFileName
      
  # remplacer les liens des images
done

chown -R www-data:www-data $DEST
chmod -R 755 $DEST
