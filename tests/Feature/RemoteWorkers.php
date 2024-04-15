<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL;
use Tests\TestCase;

class RemoteWorkers extends TestCase
{
    protected function setUp() : void
    {
        parent::setUp();

        URL::forceRootUrl('http://localhost');
        Config::set('cdash.remote_workers', true);
        Config::set('cdash.backup_timeframe', 0);
    }

    public function testRemoteWorkerAPIAccess() : void
    {
        Storage::put('inbox/delete_me', 'please delete me');
        $_SERVER["REQUEST_METHOD"] = 'DELETE';
        $_REQUEST['filename'] = encrypt('inbox/delete_me');

        $response = $this
            ->delete('/api/v1/deleteSubmissionFile.php');
        $response->assertOk();
        self::assertFalse(Storage::exists('inbox/delete_me'));
    }

    public function testRemoteWorkerAPIAccessWithInvalidKey() : void
    {
        Storage::put('inbox/delete_me', 'please delete me');
        $_SERVER["REQUEST_METHOD"] = 'DELETE';
        // Not encrypted, will fail.
        $_REQUEST['filename'] = 'inbox/delete_me';

        $response = $this
            ->delete('/api/v1/deleteSubmissionFile.php');
        $response->assertConflict();
        self::assertTrue(Storage::exists('inbox/delete_me'));
        Storage::delete('inbox/delete_me');
    }
}
