project('org.spheras.desktopfolder', ['vala', 'c'],
    version: '0.0.1'
)

gnome = import('gnome')
i18n = import('i18n')

asresources = gnome.compile_resources(
    'as-resources', 'data/css.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')], language: 'vala')

conf = configuration_data()
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

c_args = [
  '-include', 'config.h',
  '-DGWEATHER_I_KNOW_THIS_IS_UNSTABLE',
]

#We need to add the math library if required
cc = meson.get_compiler('c')
m_dep = cc.find_library('m', required : false)

executable(
    'org.spheras.desktopfolder',
    'src/Application.vala',
    'src/Resources.vala',
    'src/windows/folder.vala',
    'src/windows/item.vala',
    asresources,
    c_args: c_args,
    dependencies: [
        dependency('granite'),
        dependency('gee-0.8'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('gtk+-3.0'),
        dependency('cairo'),
        dependency('gdk-pixbuf-2.0'),
        m_dep
    ],
    install : true
)

meson.add_install_script('meson/post_install.py')

subdir('data')
subdir('po')
