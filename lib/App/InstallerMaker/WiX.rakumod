use App::InstallerMaker::WiX::Configuration;
use App::InstallerMaker::WiX::PreCheck;
use App::InstallerMaker::WiX::InstallerBuilder;
use Shell::Command;

sub MAIN(Str $yaml-description) is export {
    my $conf-promise = start App::InstallerMaker::WiX::Configuration.parse(
        $yaml-description
    );
    do-pre-checks();
    my $conf = do {
        CATCH {
            bust "Parsing configuration failed. $_";
        }
        await $conf-promise;
    }

    my $work-dir = $*TMPDIR ~ '\\install-build-' ~ time;
    mkdir $work-dir;
    LEAVE rm_rf $work-dir;
    react {
        whenever build-installer($conf, $work-dir) {
            print "{.name } {'.' x 50 - .name.chars} ";
            if .success {
                say "OK";
            }
            else {
                say "FAILED";
                note .error;
                bust "A step in building the installer failed; aborting.";
            }
        }
    }
    say "Generating installer completed";
}

sub do-pre-checks() {
    my $pre-check-failed = 0;
    react {
        whenever pre-check() {
            print "{.name } {'.' x 50 - .name.chars} ";
            if .success {
                say "OK";
            }
            else {
                say "FAILED";
                $pre-check-failed++;
            }
        }
    }
    if $pre-check-failed {
        bust "$pre-check-failed pre-check(s) failed; ensure these missing " ~
             "tools are installed and in the PATH";
    }
    say "Pre-checks completed\n";
}

sub bust($message) {
    note $message;
    exit 1;
}
