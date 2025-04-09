#!/bin/sh

SLSDIR="$HOME/.local/share/SLSsteam"
SLSPATH="$SLSDIR/path"
SLSLIB="$SLSDIR/SLSsteam.so"

uninstall()
{
	test -f "$SLSDIR/steam-jupiter.bak" && sudo cp -v "$SLSDIR/steam-jupiter.bak" "$(realpath "$(type -P steam-jupiter)")" #Left over from Steam Deck patcher
	rm -v "$HOME/.config/fish/SLSsteam.fish" 2> /dev/null
	rm -v "$HOME/.local/share/applications/steam.desktop" 2> /dev/null
	rm -v "$HOME/.local/share/applications/steam-native.desktop" 2> /dev/null
	rm -rvf "$SLSDIR"
	echo "Uninstall done!"
}

install_wrapper()
{
    EXE="$1"
    FPATH="$(type -P $EXE)"

    DIRNAME="$(dirname "$FPATH")"
    if [ "$DIRNAME" = "$SLSPATH" ]; then
        echo "$EXE wrapper already installed! Skipping"
        return 0
    fi

    if [[ $? -ne 0 ]]; then
        echo "$EXE not found in path! Skipping"
        return 1
    fi

    # Если это Steam, используем LD_PRELOAD
    if [ "$EXE" = "steam" ] || [ "$EXE" = "steam-runtime" ] || [ "$EXE" = "steam-native" ]; then
        echo -e "#!/bin/sh\nLD_PRELOAD=\"$SLSLIB\" \"$FPATH\" \"\$@\"" > "$SLSPATH/$EXE"
    else
        # Для Elden Ring удаляем LD_PRELOAD
        if [[ "$EXE" = "eldenring" ]]; then
            echo -e "#!/bin/sh\nunset LD_PRELOAD\n\"$FPATH\" \"\$@\"" > "$SLSPATH/$EXE"
        else
            # Для других приложений удаляем LD_PRELOAD
            echo -e "#!/bin/sh\nunset LD_PRELOAD\nenv -u LD_PRELOAD \"$FPATH\" \"\$@\"" > "$SLSPATH/$EXE"
        fi
    fi
    chmod u+x "$SLSPATH/$EXE"
    echo "Created wrapper for $FPATH at $SLSPATH/$EXE"
    return 0
}

install_desktop_file()
{
    NAME="$1.desktop"
    USR_APP_DIR="$HOME/.local/share/applications"
    APP_DIR="/usr/share/applications"

    # Проверяем, существует ли файл ярлыка
    if [ ! -f "$APP_DIR/$NAME" ]; then
        echo "$NAME not found in applications! Skipping"
        return 1
    fi

    # Создаём директорию для пользовательских ярлыков, если её нет
    if [ ! -d "$USR_APP_DIR" ]; then
        mkdir -p "$USR_APP_DIR"
        if [[ $? -ne 0 ]]; then
            echo "Failed to create $USR_APP_DIR! Aborting .desktop creation"
            return 1
        fi
    fi

    # Копируем ярлык и заменяем LD_AУДИТ на LD_PRELOAD
    cp "$APP_DIR/$NAME" "$USR_APP_DIR/"
    sed -i "s|^Exec=/|Exec=env LD_PRELOAD=\"$SLSLIB\" /|" "$USR_APP_DIR/$NAME"
    echo "Created $USR_APP_DIR/$NAME"
}

install_path()
{
	SHELLPATH="$(realpath "$SHELL")"
	CMD="$(echo "export PATH=\"$SLSPATH:\$PATH\"")"

	if [ "$SHELLPATH" = "/usr/bin/fish" ]; then
		SLSSTEAM_FISH="$HOME/.config/fish/conf.d/SLSsteam.fish"
		if [ ! -f "$SLSSTEAM_FISH" ]; then
			echo "$CMD" > "$SLSSTEAM_FISH"
			echo "Wrote $CMD to $SLSSTEAM_FISH"

			echo "Relog for changes to take effect!"
		fi
	else
		echo "User is on unsupported shell! Skipping path installation"
		return 1
	fi

	return 0
}

install_slssteam()
{
    LIB="./bin/SLSsteam.so"
    if [ ! -f "$LIB" ]; then
        echo "bin/SLSsteam.so not found! Did you run the install.sh in the correct directory?"
        exit 1
    fi

    if [ ! -d "$SLSDIR" ]; then
        mkdir "$SLSDIR"
        if [[ $? -ne 0 ]]; then
            echo "Unable to create $SLSDIR! Aborting"
            exit 1
        fi
    fi

    if [ ! -d "$SLSPATH" ]; then
        mkdir "$SLSPATH"
        if [[ $? -ne 0 ]]; then
            echo "Unable to create $SLSPATH! Aborting"
            exit 1
        fi
    fi

    # Копируем библиотеку SLSsteam.so
    cp -v "$LIB" "$SLSDIR/"

    # Добавляем проверку в библиотеке
    echo "if (getenv(\"LD_PRELOAD\") && strcmp(getenv(\"LD_PRELOAD\"), \"$SLSLIB\") != 0) unsetenv(\"LD_PRELOAD\");" >> "$SLSDIR/SLSsteam.so"
}

install_all()
{
	install_slssteam

	install_path
	if [[ $? -eq 0 ]]; then
		install_wrapper steam
		install_wrapper steam-runtime
		#Wrapping the steam-jupiter doesn't work, probably doesn't get called from PATH
		install_wrapper steam-native
	fi

	install_desktop_file steam
	#No steam-runtime.desktop (atleast on my Arch install...)
	install_desktop_file steam-native

	echo "Install script done! If any wrappers or .desktop files have been created it was successfull."
}

if [[ $# -lt 1 ]]; then
	echo "Usage: $0 install|uninstall"
	exit 0
fi

if [ "$1" == "install" ]; then
	install_all
elif [ "$1" == "uninstall" ]; then
	uninstall
else
	echo "Unknown command $1!"
	exit 1
fi
