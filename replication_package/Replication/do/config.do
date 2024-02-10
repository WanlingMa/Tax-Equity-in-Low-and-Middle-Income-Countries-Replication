// Derived from https://github.com/gslab-econ/template/blob/master/config/config_stata.do
// with minor corrections

clear all
set more off

program main
    * *** Add required packages from SSC to this list ***
    local ssc_packages "asdoc niceloglabels palettes colrspace"
    * *** Add required packages from SSC to this list ***

    if !missing("`ssc_packages'") {
        foreach pkg in `ssc_packages' {
        * install using ssc, but avoid re-installing if already present
            capture which `pkg'
            if _rc == 111 {                 
               dis "Installing `pkg'"
               quietly ssc install `pkg', replace
               }
        }
    }

    * Install packages using net, but avoid re-installing if already present
    *capture which yaml
    *   if _rc == 111 {
    *    quietly cap ado uninstall yaml
    *    quietly net install yaml, from("https://raw.githubusercontent.com/gslab-econ/stata-misc/master/")
    *   }
    * Install complicated packages : moremata (which cannot be tested for with which)
    capture confirm file $adobase/plus/m/moremata.hlp
        if _rc != 0 {
        cap ado uninstall moremata
        ssc install moremata
        }

end

main

/*==============================================================================================*/
/* after installing all packages, it may be necessary to issue the mata mlib index command */
/* This should always be the LAST command after installing all packages                    */

	mata: mata mlib index
