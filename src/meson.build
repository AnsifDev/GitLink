gitlink_sources = [
  'main.vala',
  'application.vala',
  'window.vala',
]

gitlink_deps = [
  dependency('gtk4'),
  dependency('libadwaita-1', version: '>= 1.4'),
]

blueprints_src = [
    'window.blp'
]

blueprints_ui = []
blueprints_vala = []
blueprints_src_path = []
foreach b : blueprints_src
  blueprints_src_path += b
	blueprints_ui += b.replace('.blp', '.ui')
	blueprints_vala += b + '.vala'
endforeach


blueprints = custom_target('blueprints',
  input: blueprints_src_path,
  output: blueprints_ui,
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTDIR@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)

blueprints_hack = custom_target('blueprints_hack',
	input: blueprints,
	output: blueprints_vala,
	command: [find_program('touch'), '@OUTPUT@'],
)

gitlink_sources += gnome.compile_resources('gitlink-resources',
  'gitlink.gresource.xml',
  dependencies: blueprints,
  c_name: 'gitlink'
)

executable('gitlink', gitlink_sources,
  dependencies: gitlink_deps,
  vala_args: [
  	'--target-glib=2.50',
  	'--gresourcesdir=src/',
  ],
  install: true,
  export_dynamic: true
)
