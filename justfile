# Justfile for starlark-syntax-go

set shell := ["bash", "-cu"]

copybara_version := "20251215"
copybara_jar := "/tmp/copybara_deploy.jar"

# List available recipes
default:
    @just --list

# Download Copybara JAR if not present
[private]
ensure-copybara:
    @if [ ! -f "{{copybara_jar}}" ]; then \
        echo "Downloading Copybara {{copybara_version}}..."; \
        curl -fsSL -o "{{copybara_jar}}" \
            "https://github.com/google/copybara/releases/download/v{{copybara_version}}/copybara_deploy.jar"; \
    fi

# Validate Copybara config
validate-copybara: ensure-copybara
    java -jar "{{copybara_jar}}" validate .copybara/copy.bara.sky

# Format all Go files
fmt:
    gofmt -w .

# Check Go formatting
fmt-check:
    @gofmt -l . | grep . && exit 1 || echo "All files formatted"

# Run all checks (used by CI)
check: fmt-check validate-copybara
