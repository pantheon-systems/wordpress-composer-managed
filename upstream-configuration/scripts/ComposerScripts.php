<?php

/**
 * @file
 * Contains \WordPressComposerManaged\ComposerScripts.
 */

namespace WordPressComposerManaged;

use Composer\Script\Event;

class ComposerScripts
{
   /**
    * Prepare for Composer to update dependencies.
    *
    * Composer will attempt to guess the version to use when evaluating
    * dependencies for path repositories. This has the undesirable effect
    * of producing different results in the composer.lock file depending on
    * which branch was active when the update was executed. This can lead to
    * unnecessary changes, and potentially merge conflicts when working with
    * path repositories on Pantheon multidevs.
    *
    * To work around this problem, it is possible to define an environment
    * variable that contains the version to use whenever Composer would normally
    * "guess" the version from the git repository branch. We set this invariantly
    * to "dev-main" so that the composer.lock file will not change if the same
    * update is later ran on a different branch.
    *
    * @see https://github.com/composer/composer/blob/main/doc/articles/troubleshooting.md#dependencies-on-the-root-package
    */
    public static function preUpdate(Event $event)
    {
        $io = $event->getIO();

        // We will only set the root version if it has not already been overriden
        if (!getenv('COMPOSER_ROOT_VERSION')) {
            // This is not an error; rather, we are writing to stderr.
            $io->writeError("<info>Using version 'dev-main' for path repositories.</info>");

            putenv('COMPOSER_ROOT_VERSION=dev-main');
        }
    }

   /**
    * Update the composer.lock file and so on.
    *
    * Upstreams should *not* commit the composer.lock file. If a local working
    * copy
    */
    private static function updateLocalDependencies($io, $packages)
    {
        if (!file_exists('composer.lock')) {
            return;
        }

        $io->writeError("<warning>composer.lock file present; do not commit composer.lock to a custom upstream, but updating for the purpose of local testing.");

        // Remove versions from the parameters, if any
        $versionlessPackages = array_map(
            function ($package) {
                return preg_replace('/:.*/', '', $package);
            },
            $packages
        );

        // Update the project-level composer.lock file
        $versionlessPackagesParam = implode(' ', $versionlessPackages);
        $cmd = "composer update $versionlessPackagesParam";
        $io->writeError($cmd . PHP_EOL);
        passthru($cmd);
    }
}
