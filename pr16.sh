#!/bin/bash

REMOTE_PATH="/var/www/pterodactyl/resources/views/layouts/admin.blade.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 Menyembunyikan menu Admin Sidebar untuk selain ID 1..."

if [ -f "$REMOTE_PATH" ]; then
  mv "$REMOTE_PATH" "$BACKUP_PATH"
  echo "📦 Backup file lama dibuat di $BACKUP_PATH"
fi

# Unduh/Salin kembali layout dasar dan injeksikan proteksi kondisional Laravel Blade
cat > "$REMOTE_PATH" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>{{ config('app.name', 'Pterodactyl') }} - Admin</title>
    <meta content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" name="viewport">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <link rel="apple-touch-icon" sizes="180x180" href="/favicons/apple-touch-icon.png">
    <link rel="icon" type="image/png" sizes="32x32" href="/favicons/favicon-32x32.png">
    <link rel="icon" type="image/png" sizes="16x16" href="/favicons/favicon-16x16.png">
    <link rel="manifest" href="/favicons/manifest.json">
    <link rel="mask-icon" href="/favicons/safari-pinned-tab.svg" color="#bc6e3c">
    <meta name="theme-color" content="#23272a">
    @section('assets')
        <link rel="stylesheet" href="/themes/pterodactyl/vendor/bootstrap/bootstrap.min.css">
        <link rel="stylesheet" href="/themes/pterodactyl/vendor/adminlte/adminlte.min.css">
        <link rel="stylesheet" href="/themes/pterodactyl/vendor/adminlte/skins/skin-blue.min.css">
        <link rel="stylesheet" href="/themes/pterodactyl/vendor/sweetalert/sweetalert.min.css">
        <link rel="stylesheet" href="/themes/pterodactyl/vendor/animate/animate.min.css">
        <link rel="stylesheet" href="/themes/pterodactyl/vendor/font-awesome/font-awesome.min.css">
        <link rel="stylesheet" href="/themes/pterodactyl/vendor/ionicons/ionicons.min.css">
        <link rel="stylesheet" href="/themes/pterodactyl/css/pterodactyl.css">
    @show
</head>
<body class="hold-transition skin-blue sidebar-mini">
<div class="wrapper">
    <header class="main-header">
        <a href="{{ route('index') }}" class="logo">
            <span class="logo-mini"><b>P</b>T</span>
            <span class="logo-lg"><b>Pterodactyl</b></span>
        </a>
        <nav class="navbar navbar-static-top" role="navigation">
            <a href="#" class="sidebar-toggle" data-toggle="push-menu" role="button">
                <span class="sr-only">Toggle navigation</span>
            </a>
            <div class="navbar-custom-menu">
                <ul class="nav navbar-nav">
                    <li class="user-menu">
                        <a href="{{ route('account') }}">
                            <img src="https://www.gravatar.com/avatar/{{ md5(strtolower(Auth::user()->email)) }}?s=160" class="user-image" alt="User Image">
                            <span class="hidden-xs">{{ Auth::user()->name_first }} {{ Auth::user()->name_last }}</span>
                        </a>
                    </li>
                    <li>
                        <a href="{{ route('index') }}" data-toggle="tooltip" data-placement="bottom" title="Exit Admin Control">
                            <i class="fa fa-server"></i>
                        </a>
                    </li>
                    <li>
                        <a href="{{ route('auth.logout') }}" data-toggle="tooltip" data-placement="bottom" title="Logout">
                            <i class="fa fa-sign-out"></i>
                        </a>
                    </li>
                </ul>
            </div>
        </nav>
    </header>
    <aside class="main-sidebar">
        <section class="sidebar">
            <ul class="sidebar-menu" data-widget="tree">
                <li class="header">BASIC MANAGEMENT</li>
                <li class="{{ Route::currentRouteName() !== 'admin.index' ?: 'active' }}">
                    <a href="{{ route('admin.index') }}">
                        <i class="fa fa-home"></i> <span>Overview</span>
                    </a>
                </li>
                
                @if(Auth::user()->id === 1)
                <li class="{{ !str_starts_with(Route::currentRouteName(), 'admin.api.') ?: 'active' }}">
                    <a href="{{ route('admin.api.index') }}">
                        <i class="fa fa-gamepad"></i> <span>API Application</span>
                    </a>
                </li>
                @endif

                <li class="header">ADMINISTRATIVE MANAGEMENT</li>
                <li class="{{ !str_starts_with(Route::currentRouteName(), 'admin.users') ?: 'active' }}">
                    <a href="{{ route('admin.users') }}">
                        <i class="fa fa-users"></i> <span>Users</span>
                    </a>
                </li>
                <li class="{{ !str_starts_with(Route::currentRouteName(), 'admin.servers') ?: 'active' }}">
                    <a href="{{ route('admin.servers') }}">
                        <i class="fa fa-server"></i> <span>Servers</span>
                    </a>
                </li>

                @if(Auth::user()->id === 1)
                <li class="{{ !str_starts_with(Route::currentRouteName(), 'admin.nodes') ?: 'active' }}">
                    <a href="{{ route('admin.nodes') }}">
                        <i class="fa fa-sitemap"></i> <span>Nodes</span>
                    </a>
                </li>
                <li class="{{ !str_starts_with(Route::currentRouteName(), 'admin.mounts') ?: 'active' }}">
                    <a href="{{ route('admin.mounts') }}">
                        <i class="fa fa-hdd-o"></i> <span>Mounts</span>
                    </a>
                </li>
                <li class="{{ !str_starts_with(Route::currentRouteName(), 'admin.locations') ?: 'active' }}">
                    <a href="{{ route('admin.locations') }}">
                        <i class="fa fa-globe"></i> <span>Locations</span>
                    </a>
                </li>
                <li class="header">SERVICE MANAGEMENT</li>
                <li class="{{ !str_starts_with(Route::currentRouteName(), 'admin.nests') ?: 'active' }}">
                    <a href="{{ route('admin.nests') }}">
                        <i class="fa fa-th-large"></i> <span>Nests</span>
                    </a>
                </li>
                <li class="header">PTERODACTYL SETTINGS</li>
                <li class="{{ !str_starts_with(Route::currentRouteName(), 'admin.settings') ?: 'active' }}">
                    <a href="{{ route('admin.settings') }}">
                        <i class="fa fa-gear"></i> <span>Settings</span>
                    </a>
                </li>
                @endif
            </ul>
        </section>
    </aside>
    <div class="content-wrapper">
        <section class="content-header">
            @yield('content-header')
        </section>
        <section class="content">
            <div class="row">
                <div class="col-xs-12">
                    @if (count($errors) > 0)
                        <div class="alert alert-danger">
                            <strong>There were some problems with your input.</strong><br><br>
                            <ul>
                                @foreach ($errors->all() as $error)
                                    <li>{{ $error }}</li>
                                @endforeach
                            </ul>
                        </div>
                     Sandra  @endif
                    @foreach (Alert::getMessages() as $type => $messages)
                        @foreach ($messages as $message)
                            <div class="alert alert-{{ $type }} alert-dismissable" role="alert">
                                <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                                {!! $message !!}
                            </div>
                        @endforeach
                    @endforeach
                </div>
            </div>
            @yield('content')
        </section>
    </div>
    <footer class="main-footer">
        <div class="pull-right hidden-xs">
            <b>Version</b> {{ config('app.version', 'Unknown') }}
        </div>
        <strong>Copyright &copy; 2015-{{ date('Y') }} <a href="https://pterodactyl.io">Pterodactyl Software</a>.</strong> All rights reserved.
    </footer>
</div>
@section('footer-scripts')
    <script src="/themes/pterodactyl/vendor/javascript/pterodactyl.js"></script>
    <script src="/themes/pterodactyl/vendor/jquery/jquery.min.js"></script>
    <script src="/themes/pterodactyl/vendor/bootstrap/bootstrap.min.js"></script>
    <script src="/themes/pterodactyl/vendor/adminlte/adminlte.min.js"></script>
    <script src="/themes/pterodactyl/vendor/sweetalert/sweetalert.min.js"></script>
    <script src="/themes/pterodactyl/vendor/slimscroll/jquery.slimscroll.min.js"></script>
    <script src="/themes/pterodactyl/vendor/socket.io/socket.io.js"></script>
    <script src="/themes/pterodactyl/vendor/bootstrap-notify/bootstrap-notify.min.js"></script>
    <script src="/js/autocomplete.js" type="text/javascript"></script>
@show
</body>
</html>
EOF

chmod 644 "$REMOTE_PATH"
echo "✅ Semua Menu pada Menu Admin berhasil disembunyikan untuk selain ID 1!"
