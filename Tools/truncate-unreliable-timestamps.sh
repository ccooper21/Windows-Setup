find . -type f -newer start -exec touch -d "@0" {} \;
