<?php
/**
 * Escapes tags found in search data
 */

if (! isset($argv[1])) {
    echo "[FAILED] No search index file provided\n";
    exit(1);
}

$searchIndexFile = $argv[1];

if (! file_exists($searchIndexFile)) {
    printf("[FAILED] Search index file '%s' does not exist\n", $searchIndexFile);
    exit(1);
}

$json = file_get_contents($searchIndexFile);

try {
    $index = json_decode($json, true, 512, JSON_THROW_ON_ERROR);
} catch (Throwable $e) {
    printf("[FAILED] Could not parse file '%s': %s\n", $searchIndexFile, $e->getMessage());
    exit(1);
}

if (! isset($index['docs'])) {
    printf("[FAILED] Invalid search index structure in file '%s'\n", $searchIndexFile);
    exit(1);
}

$index['docs'] = array_map(function ($item) {
    $item['text'] = htmlspecialchars($item['text'], ENT_HTML5 | ENT_NOQUOTES | ENT_SUBSTITUTE, 'UTF-8', false);
    return $item;
}, $index['docs']);

$json = json_encode($index, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

file_put_contents($searchIndexFile, $json);
