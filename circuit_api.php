<?php
header('Content-Type: application/json; charset=utf-8');
$dir = __DIR__ . '/circuits';
if (!is_dir($dir)) mkdir($dir, 0755, true);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $raw = file_get_contents('php://input');
    $code = strval(rand(1000, 9999));
    file_put_contents("$dir/$code.json", $raw);
    echo json_encode(['ok' => true, 'code' => $code]);
    exit;
}

if (isset($_GET['code'])) {
    $code = preg_replace('/[^0-9]/', '', $_GET['code']);
    $file = "$dir/$code.json";
    if (file_exists($file)) {
        echo file_get_contents($file);
    } else {
        http_response_code(404);
        echo json_encode(['error' => 'Not found']);
    }
}
?>
