<?php

declare(strict_types=1);

$ref   = getenv('GITHUB_REF');
$repo  = getenv('GITHUB_REPOSITORY');
$token = getenv('GITHUB_TOKEN');

function buildDocs() {
    echo "TRUE";
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
    curl_init('https://api.github.com/repos/' . $repo . '/' . $resource);
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
    usort($payload, $compareRefNames);
    return $payload;
}

function extractMajorMinorVersion(string $version): string
{
    $matches = [];
    preg_match('/^(?P<release>\d+\.\d+)\./', $version, $matches);
    return $matches['release'] ?? $version;
}

if ('master' === $ref) {
    // Assume that release branches are not in use if we detect a push to master
    buildDocs();
    exit(0); // redundant; placed here to note that buildDocs exits
}

if (! preg_match('/^\d+\.\d+\.x$/', $ref)) {
    // Not a release branch
    skipDocs();
    exit(0); // redundant; placed here to note that skipDocs exits
}

$compareRefNames = function ($a, $b) {
    $a = preg_replace('/\.x$/', '.0', $a);
    $b = preg_replace('/\.x$/', '.0', $b);
    return version_compare($a, $b);
};

$branches = executeApiCall($repo, 'branches', $token);
$branches = array_filter($branches, function ($branch) {
    return (bool) preg_match('/^\d+\.\d+\.x$/', $branch);
});
$mostRecent = array_pop($branches);
if ($mostRecent === $ref) {
    buildDocs();
    exit(0); // redundant; placed here to note that buildDocs exits
}

$tags = executeApiCall($repo, 'tags', $token);
$committedReleaseVersion = extractMajorMinorVersion($ref);
$mostRecentReleaseVersion = extractMajorMinorVersion(array_pop($tags));
if ($committedReleaseVersion !== $mostRecentReleaseVersion) {
    skipDocs();
    exit(0); // redundant; placed here to note that skipDocs exits
}
buildDocs();
