gitlink_sources = [
  'main.vala',
  'application.vala',
  'window.vala',
]

gitlink_deps = [
  dependency('gtk4'),
  dependency('libadwaita-1', version: '>= 1.4'),
]

gitlink_sources += gnome.compile_resources('gitlink-resources',
  'gitlink.gresource.xml',
  c_name: 'gitlink'
)

executable('gitlink', gitlink_sources,
  dependencies: gitlink_deps,
       install: true,
)
