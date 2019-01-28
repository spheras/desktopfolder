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

desktop_exe = configure_file(   input : meson.project_name() + '.desktop.in',
                                output : 'desktopfolder_with_executable_name.desktop.in',
                                configuration : desktop_conf)

i18n.merge_file (
    'appdata',
    input: meson.project_name() + '.appdata.xml.in',
    output: meson.project_name() + '.appdata.xml',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo'),
    po_dir: join_paths(meson.source_root (), 'po')
)

i18n.merge_file (
    'desktop',
    input: desktop_exe,
    output: meson.project_name() + '.desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications'),
    po_dir: join_paths(meson.source_root (), 'po'),
    type: 'desktop'
)

i18n.merge_file (
    'desktop',
    input: desktop_exe,
    output: meson.project_name() + '-autostart.desktop',
    install: true,
    install_dir: '/etc/xdg/autostart',
    po_dir: join_paths(meson.source_root (), 'po'),
    type: 'desktop'
)