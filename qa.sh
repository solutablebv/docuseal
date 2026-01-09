#!/bin/bash
set -e

echo "Running QA checks..."
echo ""

# Check and install dependencies if needed
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Checking dependencies..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Install build tools if needed (for native extensions)
if ! command -v make &> /dev/null; then
    echo "Installing build tools..."
    apk add --no-cache build-base || echo "Warning: Could not install build tools. Some gems may fail to install."
fi

# Install Node.js and yarn if needed
if ! command -v node &> /dev/null; then
    echo "Installing Node.js and yarn..."
    apk add --no-cache nodejs yarn || echo "Warning: Could not install Node.js/yarn. ESLint will be skipped."
fi

# Install Node dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "Installing Node dependencies..."
    yarn install --network-timeout 1000000 || echo "Warning: Could not install Node dependencies. ESLint will be skipped."
fi

# Install development/test gems if not available
if ! bundle show rubocop &> /dev/null; then
    echo "Installing development/test gems..."
    bundle config unset without
    bundle install --with development test || {
        echo "Warning: Could not install development/test gems. Some checks will be skipped."
        echo "This may require build tools. Trying to continue with available tools..."
    }
fi

echo ""

# Run RuboCop
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Running RuboCop..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if bundle show rubocop &> /dev/null; then
    bundle exec rubocop
    echo "✓ RuboCop passed"
else
    echo "⚠ RuboCop skipped (not available)"
fi
echo ""

# Run ErbLint
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Running ErbLint..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if bundle show erb_lint &> /dev/null; then
    bundle exec erb_lint ./app
    echo "✓ ErbLint passed"
else
    echo "⚠ ErbLint skipped (not available)"
fi
echo ""

# Run ESLint
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Running ESLint..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f "./node_modules/eslint/bin/eslint.js" ]; then
    ./node_modules/eslint/bin/eslint.js "app/javascript/**/*.js"
    echo "✓ ESLint passed"
else
    echo "⚠ ESLint skipped (not available)"
fi
echo ""

# Run Brakeman
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Running Brakeman..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if bundle show brakeman &> /dev/null; then
    bundle exec brakeman -q --exit-on-warn
    echo "✓ Brakeman passed"
else
    echo "⚠ Brakeman skipped (not available)"
fi
echo ""

# Run RSpec (requires database setup)
if [ "${SKIP_RSPEC:-false}" != "true" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Running RSpec..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Note: RSpec requires database setup. Set SKIP_RSPEC=true to skip."
    if [ -z "${DATABASE_URL}" ]; then
        echo "Warning: DATABASE_URL not set. RSpec may fail."
    fi
    if bundle show rspec &> /dev/null; then
        bundle exec rspec
        echo "✓ RSpec passed"
    else
        echo "⚠ RSpec skipped (not available)"
    fi
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "QA checks completed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

