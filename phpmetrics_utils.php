<?php

if (count($argv) < 2) {
    exit(124);
}
$type = $argv[1];

const METRICS_DIR = __DIR__ . '/public/phpmetrics/js';
$latest = METRICS_DIR . '/latest.json';
if (!\is_file($latest)) {
    exit(404);
}

switch ($type) {
    case 'analyse':
        analysis('errors', $latest);
        analysis('criticals', $latest);
        echo "\e[92mALL CLEAR AND UNDER CONTROL\e[0m \n";
        exit(0);
    case 'generate':
        generate($latest);
        echo "\e[94mBASELINE GENERATED\e[0m \n";
        exit(0);
    default:
        echo "\e[31mACTION `$type` NOT FOUND\e[0m \n";
        exit(200);
}

function generate(string $latest)
{
    echo "\e[31mThis action will replace current baseline with the latest analyse results. Are you sure ?\e[0m ";
    $valid = readline("[Y/N]");

    if (empty($valid) || strtoupper($valid) !== 'Y') {
        echo "\e[94mCANCELLING BASELINE GENERATION\e[0m \n";
        exit(0);
    }
    file_put_contents(__DIR__ . '/.phpmetrics_baseline.json', file_get_contents($latest));
}

function analysis($analysis, $latest)
{
    $baselineFile = __DIR__ . '/.phpmetrics_baseline.json';
    if (!\is_file($baselineFile)) {
        exit(404);
    }

    $current = json_decode(file_get_contents($latest), true);

    switch ($analysis) {
        case 'errors':
            $baseline = json_decode(file_get_contents($baselineFile), true);
            $baselineErrors = (int) $baseline['sum']['violations']['error'];
            $currentErrors = (int) $current['sum']['violations']['error'];
            if ($baselineErrors < $currentErrors) {
                $count = $currentErrors - $baselineErrors;
                echo "\e[31m$count NEW ERROR(S)\e[0m\n";
                exit($currentErrors - $baselineErrors);
            }
            break;
        case 'criticals':
            $currentCritical = (int) $current['sum']['violations']['critical'];

            if ($currentCritical > 0) {
                echo "\e[31m$currentCritical CRITICAL\e[0m\n";
                exit($currentCritical);
            }
            break;
        default:
            exit(200);
    }
}
