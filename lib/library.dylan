Module: dylan-user

define library gendoc-lib
  use collections,
    import: { table-extensions };
  use command-line-parser;
  use common-dylan;
  use dylan-tool-lib,
    import: { pacman, %pacman };
  use io,
    import: { format, format-out };
  use logging;
  use strings;
  use system,
    import: { file-system, locators, operating-system };

  export
    gendoc-impl;
end;

define module gendoc-impl
  use command-line-parser;
  use common-dylan;
  use file-system,
    prefix: "fs/";
  use format;
  use format-out;
  use locators;
  use logging;
  use operating-system,
    prefix: "os/";
  use pacman,
    prefix: "pm/";
  // TODO: export find-release from pacman
  use %pacman,
    prefix: "%pm/";
  use strings;
  use table-extensions,
    rename: { <case-insensitive-string-table> => <istring-table> };

  export
    main;
end;
