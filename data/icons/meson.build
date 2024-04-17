application_id = 'com.asiet.lab.GitLink'

scalable_dir = 'hicolor' / 'scalable' / 'apps'
install_data(
  scalable_dir / ('@0@.svg').format(application_id),
  install_dir: get_option('datadir') / 'icons' / scalable_dir
)

symbolic_dir = join_paths('hicolor', 'symbolic', 'apps')
install_data(
  [
    join_paths(symbolic_dir, ('@0@-symbolic.svg').format(application_id)),
    join_paths(symbolic_dir, ('settings-symbolic.svg')),
    join_paths(symbolic_dir, ('arrow-into-box-symbolic.svg')),
    join_paths(symbolic_dir, ('chain-link-symbolic.svg')),
    join_paths(symbolic_dir, ('earth-symbolic.svg')),
    join_paths(symbolic_dir, ('user-trash-symbolic.svg')),
    join_paths(symbolic_dir, ('application-exit-rtl-symbolic.svg')),
    join_paths(symbolic_dir, ('view-refresh-symbolic.svg')),
    join_paths(symbolic_dir, ('error-symbolic.svg')),
    join_paths(symbolic_dir, ('warning-symbolic.svg')),
    join_paths(symbolic_dir, ('key-symbolic.svg')),
    join_paths(symbolic_dir, ('fingerprint-symbolic.svg')),
    join_paths(symbolic_dir, ('check-round-outline-symbolic.svg')),
    join_paths(symbolic_dir, ('arrow2-right-symbolic.svg')),
  ],
  install_dir: get_option('datadir') / 'icons' / symbolic_dir
)
