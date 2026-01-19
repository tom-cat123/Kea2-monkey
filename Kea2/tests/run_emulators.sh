#!/bin/bash
# Compatibility tests for Kea4Fastbot against different Android versions
### Example: ./run_emulators.sh "system-images;android-32;google_apis;x86_64"

# Obtain all android versions which are compatible with intel chips
# sdkmanager --list | grep -E "system-images;android-[0-9]+;(google_apis).*(x86|x86_64)"
###  
###  system-images;android-36;google_apis;x86_64    => Android 16
###  system-images;android-35;google_apis;x86_64    => Android 15
###  system-images;android-34;google_apis;x86_64    => Android 14
###  system-images;android-33;google_apis;x86_64    => Android 13
###  system-images;android-32;google_apis;x86_64    => Android 12
###  system-images;android-31;google_apis;x86_64    => Android 12
###  system-images;android-30;google_apis;x86_64    => Android 11
###  system-images;android-29;google_apis;x86_64    => Android 10
###  system-images;android-28;google_apis;x86_64    => Android 9
###  system-images;android-27;google_apis;x86       => Android 8
###  system-images;android-26;google_apis;x86_64    => Android 8
###  system-images;android-25;google_apis;x86_64    => Android 7
###  system-images;android-24;google_apis;x86_64    => Android 7
###  system-images;android-23;google_apis;x86_64    => Android 6
###  system-images;android-22;google_apis;x86_64    => Android 5
###  system-images;android-21;google_apis;x86_64    => Android 5
###  system-images;android-19;google_apis;x86       => Android 4

# Obtain all android versions which are compatible with Apple Silicon (M1, M2, M3 chips)
# sdkmanager --list | grep -E "system-images;android-[0-9]+;google_apis;arm64-v8a"
###  system-images;android-34;google_apis;arm64-v8a    => Android 14
###  system-images;android-33;google_apis;arm64-v8a    => Android 13
###  system-images;android-32;google_apis;arm64-v8a    => Android 12
###  system-images;android-31;google_apis;arm64-v8a   => Android 12
###  system-images;android-30;google_apis;arm64-v8a   => Android 11
###  system-images;android-29;google_apis;arm64-v8a    => Android 10
###  system-images;android-28;google_apis;arm64-v8a    => Android 9
###  system-images;android-27;google_apis;arm64-v8a      => Android 8
###  system-images;android-26;google_apis;arm64-v8a   => Android 8
###  system-images;android-25;google_apis;arm64-v8a   => Android 7
###  system-images;android-24;google_apis;arm64-v8a    => Android 7
###  system-images;android-23;google_apis;arm64-v8a    => Android 6
###  system-images;android-22;google_apis;arm64-v8a    => Android 5
###  system-images;android-21;google_apis;arm64-v8a   => Android 5

QUICKSTART=../quickstart.py

# Detect the operating system
OS=$(uname)
case "$OS" in
    Darwin)
        OS_TYPE="macos"
        ;;
    Linux)
        OS_TYPE="linux"
        ;;
    MINGW*|CYGWIN*|MSYS*)
        OS_TYPE="windows"
        ;;
    *)
        echo "Unsupported operating system: $OS"
        exit 1
        ;;
esac

# display help and list available Android versions
display_help() {
    echo "Usage: $0 <android_version>"
    echo "This script uses sdkmanager to install a specific Android version and avdmanager to create a new emulator."
    echo "Available Android versions:"
    sdkmanager --list | grep -E "^  system-images;android-"
    exit 0
}

# check if an Android version is already installed
is_version_installed() {
    local_version=$1
    sdkmanager --list_installed | grep -q "^  $local_version"
    return $?
}

# Function to wait for the emulator to boot
wait_for_emulator() {
    local_avd_name=$1
    boot_completed=false
    while [ "$boot_completed" = false ]; do
        boot_status=$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
        if [ "$boot_status" = "1" ]; then
            boot_completed=true
            echo "Emulator $local_avd_name has fully booted."
        else
            echo "Waiting for emulator $local_avd_name to boot..."
            sleep 5
        fi
    done
}

# Function to safely shut down the emulator
shutdown_emulator() {
    local_avd_name=$1
    echo "Shutting down emulator $local_avd_name..."
    adb -s emulator-5554 emu kill
    echo "Waiting for emulator $local_avd_name to shut down..."
    while adb devices | grep -q "emulator-5554"; do
        sleep 2
    done
    echo "Emulator $local_avd_name has been shut down."
}

# Check if the user asks for help
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    display_help
fi

# Check if the Android version argument is provided
if [ $# -eq 0 ]; then
    echo "Error: Please provide the Android version as an argument."
    echo "Usage: $0 <android_version>"
    echo "Use -h or --help to list available Android versions."
    exit 1
fi

# Define the Android version to be installed
ANDROID_VERSION=$1
# Define the name of the emulator
AVD_NAME=`echo $ANDROID_VERSION | cut -d ';' -f 2 | tr -d '\n' `

# Check if the Android version is already installed
if is_version_installed "$ANDROID_VERSION"; then
    echo "Android version $ANDROID_VERSION is already installed. Skipping installation."
else
    # Install the Android version
    echo "Installing Android version: $ANDROID_VERSION"

    case "$OS_TYPE" in
        windows)
            # On Windows, we may need to handle batch file execution differently
            yes | sdkmanager.bat "$ANDROID_VERSION"
            ;;
        *)
            yes | sdkmanager "$ANDROID_VERSION"
            ;;
    esac

    # Check if the installation was successful
    if [ $? -eq 0 ]; then
        echo "Android version $ANDROID_VERSION installed successfully."
    else
        echo "Failed to install Android version $ANDROID_VERSION."
        exit 1
    fi
fi

# Function to check if the emulator is already created
is_emulator_created() {
    local_avd_name=$1
    case "$OS_TYPE" in
        windows)
            avdmanager.bat list avd | grep -q "$local_avd_name"
            ;;
        *)
            avdmanager list avd | grep -q "$local_avd_name"
            ;;
    esac
    return $?
}


# Check if the emulator is already created
if is_emulator_created "$AVD_NAME"; then
    echo "Emulator $AVD_NAME is already created. Skipping creation."
else
    # Create a new emulator
    echo "Creating a new emulator: $AVD_NAME"

    if [[ $ANDROID_VERSION == *"arm64-v8a"* ]]; then
        ABI="google_apis/arm64-v8a"
    elif [[ $ANDROID_VERSION == *"x86_64"* ]]; then
        ABI="google_apis/x86_64"
    else 
        ABI="google_apis/x86"
    fi

    case "$OS_TYPE" in
        windows)
            echo "no" | avdmanager.bat create avd -n "$AVD_NAME" -k "$ANDROID_VERSION"
            ;;
        *)
        echo "no" | avdmanager create avd --force --name "$AVD_NAME" --package "$ANDROID_VERSION" --abi "$ABI" --sdcard 1024M --device 'Nexus 7'
        ;;
    esac

    # Check if the creation was successful
    if [ $? -eq 0 ]; then
        echo "Emulator $AVD_NAME created successfully."
    else
        echo "Failed to create emulator $AVD_NAME."
        exit 1
    fi
fi


# Start the emulator
echo "Starting the emulator: $AVD_NAME"
case "$OS_TYPE" in
    windows)
        emulator.exe -avd "$AVD_NAME" -no-snapshot &
        ;;
    *)
        emulator -avd "$AVD_NAME" -no-snapshot &
        ;;
esac

# Wait for the emulator to boot
wait_for_emulator "$AVD_NAME"

python $QUICKSTART

# Shutdown the emulator
shutdown_emulator "$AVD_NAME"

echo "All operations completed."    