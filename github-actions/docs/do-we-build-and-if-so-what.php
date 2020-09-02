<?php

declare(strict_types=1);

/*
 * DECLARATIONS
 */
$event = getenv('GITHUB_EVENT_NAME') ?: '';
$ref   = preg_replace('#^refs/(tags|heads)/#', '', getenv('GITHUB_REF') ?: '');
$repo  = getenv('GITHUB_REPOSITORY');
$token = getenv('GITHUB_TOKEN');

/*
 * FUNCTIONS
 */
function buildDocs(string $ref) {
    echo $ref;
    exit(0);
}

function skipDocs() {
    echo "FALSE";
    exit(0);
}

/**
 * @return string[]
 */
function executeApiCall(string $repo, string $resource, string $token): array
{
    $curl = curl_init('https://api.github.com/repos/' . $repo . '/' . $resource);
    curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($curl, CURLOPT_HTTPHEADER, [
        'Authorization: bearer ' . $token,
        'User-Agent: laminas/docs',
        'Accept: application/vnd.github+json',
    ]);
    $response = curl_exec($curl);
    $payload  = json_decode($response, true);
    $payload  = array_map(static function (string $ref): string {
        return $ref['name'];
    }, $payload);
    usort($payload, 'version_compare');
    return $payload;
}

/*
 * MAIN
 */

// Push to master branch (legacy):
if ($event === 'push') {
    $ref === 'master'
        ? buildDocs('master')
        : skipDocs();
    exit(0); // redundant; placed here to note that above each exit
}

// If not a release or a repository_dispatch, skip
if (! in_array($event, ['release', 'repository_dispatch'], true)) {
    skipDocs();
    exit(0); // redundant; placed here to note that skipDocs exits
}

$tags = executeApiCall($repo, 'releases', $token);
$latestStableRelease = array_pop($tags);

// Manual build request
if ($event === 'repository_dispatch') {
    buildDocs($latestStableRelease);
    exit(0); // redundant; placed here to note that buildDocs exits
}

// Not a stable release:
if (! preg_match('/^\d+\.\d+\.\d+(?:(p|pl|patch)\d+)?$/', $ref)) {
    skipDocs();
    exit(0); // redundant; placed here to note that skipDocs exits
}

// Is this the latest release according to semver?
$ref === $latestStableRelease
    ? buildDocs($ref)
    : skipDocs();
