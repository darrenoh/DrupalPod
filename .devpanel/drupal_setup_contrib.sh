#!/usr/bin/env bash
set -eu -o pipefail

# Drupal projects with no composer.json, bypass the symlink config, symlink has to be created manually.

if [ "$DP_PROJECT_TYPE" == "project_module" ]; then
    PROJECT_TYPE=modules
elif [ "$DP_PROJECT_TYPE" == "project_theme" ]; then
    PROJECT_TYPE=themes
fi

cat <<PROJECTASYMLINK >"${APP_ROOT}"/repos/add-project-as-symlink.sh
#!/usr/bin/env bash
# This file was dynamically generated by a script
echo "Replace project with a symlink"
rm -rf web/$PROJECT_TYPE/contrib/$DP_PROJECT_NAME
cd web/$PROJECT_TYPE/contrib && ln -s ../../../repos/$DP_PROJECT_NAME .
PROJECTASYMLINK

chmod +x "${APP_ROOT}"/repos/add-project-as-symlink.sh

if [ -n "$COMPOSER_DRUPAL_LENIENT" ]; then
    # Add composer_drupal_lenient for modules on Drupal 10
    cd "${APP_ROOT}" && composer config --merge --json extra.drupal-lenient.allowed-list '["drupal/'"$DP_PROJECT_NAME"'"]'
    cd "${APP_ROOT}" && time composer require "$COMPOSER_DRUPAL_LENIENT" --no-install
fi
# Add the project to composer (it will get the version according to the branch under `/repo/name_of_project`)
cd "${APP_ROOT}" && time composer require drupal/"$DP_PROJECT_NAME" --no-interaction --no-install
