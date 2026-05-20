#!/bin/bash

REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/BaseController.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 Memasang proteksi Anti Create PTLA..."

if [ -f "$REMOTE_PATH" ]; then
  mv "$REMOTE_PATH" "$BACKUP_PATH"
  echo "📦 Backup file lama dibuat di $BACKUP_PATH"
fi

mkdir -p "$(dirname "$REMOTE_PATH")"
chmod 755 "$(dirname "$REMOTE_PATH")"

cat > "$REMOTE_PATH" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\View\View;
use Illuminate\Http\Request;
use Pterodactyl\Models\ApiKey;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Auth;
use Prologue\Alerts\AlertsMessageBag;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Services\Api\ApiKeyCreationService;

class BaseController extends Controller
{
    public function __construct(
        protected AlertsMessageBag $alert,
        protected ApiKeyCreationService $keyCreationService,
        protected ViewFactory $view
    ) {}

    public function index(): View
    {
        return $this->view->make('admin.index');
    }

    public function apiKeys(Request $request): View
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, 'Akses Menu API Application Ditolak');
        }

        return $this->view->make('admin.api.index', [
            'keys' => ApiKey::query()->where('key_type', ApiKey::TYPE_APPLICATION)->get(),
        ]);
    }

    public function createApiKey(Request $request): RedirectResponse
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, 'Dilarang Membuat PTLA');
        }

        $token = $this->keyCreationService->handle($request->user(), $request->input('memo'), ApiKey::TYPE_APPLICATION);
        $this->alert->success("Kunci aplikasi baru berhasil dibuat. Token: $token")->flash();

        return redirect()->route('admin.api.index');
    }

    public function deleteApiKey(Request $request, int $key): RedirectResponse
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, 'Dilarang Menghapus PTLA');
        }

        ApiKey::query()->where('key_type', ApiKey::TYPE_APPLICATION)->where('id', $key)->delete();
        $this->alert->success('Kunci aplikasi berhasil dihapus.')->flash();

        return redirect()->route('admin.api.index');
    }
}
EOF

chmod 644 "$REMOTE_PATH"
echo "✅ Protect Anti Create PTLA berhasil dipasang!"
