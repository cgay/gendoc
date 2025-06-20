Module: dylan-user

define library gendoc
  use collections,
    import: { table-extensions };
  use command-line-parser;
  use common-dylan;
  use deft,
    import: { pacman, %pacman, deft-shared };
  use io,
    import: { format, format-out, streams };
  use logging;
  use strings;
  use system,
    import: { file-system, locators, operating-system };

end library;

define module gendoc
  use command-line-parser;
  use common-dylan;
  use file-system, prefix: "fs/";
  use format,      prefix: "io/";
  use format-out,  prefix: "io/";
  use locators;
  use logging;
  use operating-system, prefix: "os/";
  use pacman, prefix: "pm/";
  // TODO: export find-release from pacman
  use %pacman, prefix: "%pm/";
  use deft-shared,                   // shared:deft
    // Not "deft/", due to https://github.com/dylan-lang/dylan-emacs-support/issues/36
    prefix: "deft-";
  use streams, prefix: "io/";
  use strings;
  use table-extensions,
    rename: { <case-insensitive-string-table> => <istring-table> };
  use threads,
    import: { dynamic-bind };

  export
    main;
end module;
