<?php
/**
 * @license   http://opensource.org/licenses/BSD-3-Clause BSD-3-Clause
 * @copyright Copyright (c) 2019-2020 Laminas Project (https://getlaminas.org)
 */

$docPath = isset($argv[1]) ? $argv[1] : 'doc';
$docPath = sprintf('%s/%s', getcwd(), $docPath);
$docPath = realpath($docPath);

$rdi = new RecursiveDirectoryIterator($docPath . '/book');
$rii = new RecursiveIteratorIterator($rdi, RecursiveIteratorIterator::SELF_FIRST);
$files = new RegexIterator($rii, '/\.md/', RecursiveRegexIterator::GET_MATCH);

$process = static function () use ($files) {
    $fileInfo = $files->getInnerIterator()->current();
    if (! $fileInfo->isFile()) {
        return true;
    }

    if ($fileInfo->getBasename('.md') === $fileInfo->getBasename()) {
        return true;
    }

    $file = $fileInfo->getRealPath();
    $md = file_get_contents($file);
    $md = preg_replace('#^[-*]$#m', '\\0 ', $md);
    $md = preg_replace('#^([-*] +)```#m', '\\1' . PHP_EOL . '  ```', $md);

    file_put_contents($file, $md);

    return true;
};

iterator_apply($files, $process);
