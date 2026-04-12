#!/bin/bash
# Cloudflare Pages build script.
# Set these two environment variables in the Cloudflare dashboard:
#   SUPABASE_URL
#   SUPABASE_ANON_KEY

set -e

# 1. Generate keys.dart from environment variables
cat > lib/keys.dart << EOF
const String supabaseUrl = '${SUPABASE_URL}';
const String supabaseAnonKey = '${SUPABASE_ANON_KEY}';
EOF

# 2. Install Flutter (Cloudflare doesn't have it pre-installed)
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# 3. Enable web and fetch dependencies
flutter config --enable-web
flutter pub get

# 4. Build
flutter build web --release

echo "Build complete → build/web"
