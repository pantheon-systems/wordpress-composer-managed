#!/bin/bash

SED=`which gsed || which sed`

$SED -i'' 's#"name": "pantheon-systems/wordpress-composer-managed"#"name": "pantheon-upstreams/decoupled-wordpress-composer-managed"#g' composer.json

# Because the precise spacing and formatting is unknown, new lines
# need to preserve the previous formatting, so here we duplicate the
# roots/wordpress line since the new lines need to come afterward,
# while prepending PTARGET1 and PTARGET2 in order to provide find/replace
# targets for the following step.
$SED -i'' -n 'p;s/"roots\/wordpress":/PTARGET1&/p' composer.json
$SED -i'' -n 'p;s/PTARGET1/PTARGET2&/p' composer.json
$SED -i'' -n 'p;s/PTARGET2/PTARGET3&/p' composer.json

# Having duplicated the previous lines, we do a standard replace operation.
$SED -i'' 's#PTARGET3.*#"pantheon-systems/pantheon-decoupled-auth-example": "^1.0",#g' composer.json
$SED -i'' 's#PTARGET2.*#"pantheon-systems/pantheon-decoupled": "^1.0",#g' composer.json
$SED -i'' 's#PTARGET1.*#"wpackagist-plugin/wp-gatsby": "^2.0",#g' composer.json
