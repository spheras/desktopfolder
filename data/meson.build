icon_sizes = ['16', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        join_paths('icons', i, meson.project_name() + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
    )
endforeach

install_data(
    meson.project_name() + '.gschema.xml',
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

podir = join_paths(meson.source_root(), 'po')
intltool = find_program('intltool-merge')

executable_name = exename # from root meson_options.txt

desktop_conf = configuration_data()
desktop_conf.set('exe_var', executable_name)

desktop_exe = configure_file(   input : 'com.github.spheras.desktopfolder.desktop.in',
                                output : 'desktopfolder_with_executable_name.desktop.in',
                                configuration : desktop_conf)

custom_target(  'desktop-autostart',
                input: desktop_exe,
                output: 'com.github.spheras.desktopfolder-autostart.desktop',
                command: [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
                install: true,
                install_dir: '/etc/xdg/autostart',
                build_by_default: true)

custom_target(  'desktop-app',
                input: desktop_exe,
                output: 'com.github.spheras.desktopfolder.desktop',
                command: [intltool, '--desktop-style', podir, '@INPUT@', '@OUTPUT@'],
                install: true,
                install_dir: join_paths(get_option('datadir'), 'applications'),
                build_by_default: true)

install_data(
    meson.project_name() + '.appdata.xml',
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)
