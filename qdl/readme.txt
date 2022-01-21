This install is for QDL to be run under scitokens. The only difference with a standard install
is that the library is embedded in the ${ST_HOME}/lib/scitokens-cli.jar. This contains a complete
embedded copy of QDL (needed for it to operate) which includes all currently available OA4MP
extensions for QDL. Using that rather than downloading the qdl vastly simplifies the deployment
and management.

This is a completely functional install, so you can fire up QDL from the command line,
create and save workspaces etc.

/opt/qdl
   +- bin
   |   qdl, qdl-run (executables for command line and standalone scripts)
   |
   + etc
   |  qdl-cfg.xml (configuration)
   |
   + var
      |
      + modules
      |  math-x, ext (standard extensions)
      |
      + scripts
      |
      |
      + ws (empty initially.