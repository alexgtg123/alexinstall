#!/bin/bash

REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/MountController.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 Memasang proteksi Anti Intip Mounts..."

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
use Illuminate\Support\Facades\Auth;
use Pterodactyl\Http\Controllers\Controller;
use Illuminate\Contracts\View\Factory as ViewFactory;

class MountController extends Controller
{
    public function __construct(private ViewFactory $view) {}

    public function index(): View
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, 'Dilarang Rusuh di Menu Mounts');
        }

        return $this->view->make('admin.mounts.index');
    }
}
EOF

chmod 644 "$REMOTE_PATH"
echo "✅ Protect Anti Intip Mounts berhasil dipasang!"
