<?php
/* Copyright (C) 2011-2018 Laurent Destailleur <eldy@users.sourceforge.net>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

// Protection to avoid direct call of template
if (empty($conf) || ! is_object($conf)) {
	print "Error, template page can't be called as URL";
	exit;
}

?>
<!-- BEGIN PHP TEMPLATE autoupgrade.tpl.php -->
<?php

$upload_dir = $conf->sellyoursaas->dir_temp."/autoupgrade_".$mythirdpartyaccount->id.'.tmp';
$backtopagesupport = GETPOST("backtopagesupport",'alpha') ? GETPOST("backtopagesupport",'alpha') : $_SERVER["PHP_SELF"].'?action=presend&mode=support&backfromautoupgrade=backfromautoupgrade&token='.newToken().'&contractid='.GETPOST('contractid', 'alpha').'&supportchannel='.GETPOST('supportchannel', 'alpha').'&ticketcategory_child_id='.(GETPOST('ticketcategory_child_id_back', 'alpha')?:GETPOST('ticketcategory_child_id', 'alpha')).'&ticketcategory='.(GETPOST('ticketcategory_back', 'alpha')?:GETPOST('ticketcategory', 'alpha')).'&subject'.(GETPOST('subject_back', 'alpha')?:GETPOST('subject', 'alpha'));
$stepautoupgrade = GETPOST("stepautoupgrade") ? GETPOST("stepautoupgrade") : 1;
$errortab = array();
$errors = 0;
$stringoflistofmodules = "";

if ($action == "instanceverification") {
	$confinstance = 0;
	require_once DOL_DOCUMENT_ROOT."/contrat/class/contrat.class.php";
	$object = new Contrat($db);
	$instanceselect = GETPOST("instanceselect", "alpha");
	$instanceselect = explode("_", $instanceselect);
	$idcontract = $instanceselect[1];

	if ($idcontract > 0) {
		$result=$object->fetch($idcontract);
		if ($result < 0){
			$errortab[] = $langs->trans("InstanceNotFound");
			$errors ++;
		}
		if (!$error) {
			$object->fetch_thirdparty();
			$type_db = $conf->db->type;
			$hostname_db  = $object->array_options['options_hostname_db'];
			$username_db  = $object->array_options['options_username_db'];
			$password_db  = $object->array_options['options_password_db'];
			$database_db  = $object->array_options['options_database_db'];
			$port_db      = (!empty($object->array_options['options_port_db']) ? $object->array_options['options_port_db'] : 3306);
			$prefix_db    = (!empty($object->array_options['options_prefix_db']) ? $object->array_options['options_prefix_db'] : 'llx_');
			$hostname_os  = $object->array_options['options_hostname_os'];
			$username_os  = $object->array_options['options_username_os'];
			$password_os  = $object->array_options['options_password_os'];
			$username_web = $object->thirdparty->email;
			$password_web = $object->thirdparty->array_options['options_password'];

			$newdb=getDoliDBInstance($type_db, $hostname_db, $username_db, $password_db, $database_db, $port_db);
			$newdb->prefix_db = $prefix_db;
			if (is_object($newdb) && $newdb->connected) {
				$confinstance = new Conf();
				$confinstance->setValues($newdb);
				$lastinstallinstance = $confinstance->global->MAIN_VERSION_LAST_INSTALL;
				$lastupgradelinstance = $confinstance->global->MAIN_VERSION_LAST_UPGRADE;
				$laststableupgradeversion = getDolGlobalString("SELLYOURSAAS_LAST_STABLE_VERSION_DOLIBARR");
				if (!empty($laststableupgradeversion)) {
					$match = '/^'.getDolGlobalString("SELLYOURSAAS_LAST_STABLE_VERSION_DOLIBARR").'.*/';
					if (preg_match($match,$lastinstallinstance ) || preg_match($match,$lastupgradelinstance)) {
						$errortab[] = $langs->trans("ErrorAlreadyLastStableVersion");
						$errors++;
					}
				}else {
					dol_include_once('sellyoursaas/class/packages.class.php');
					$dataofcontract = sellyoursaasGetExpirationDate($object, 0);
					$tmpproduct = new Product($db);
					$tmppackage = new Packages($db);

					if ($dataofcontract['appproductid'] > 0) {
						$tmpproduct->fetch($dataofcontract['appproductid']);
						$tmppackage->fetch($tmpproduct->array_options['options_package']);
					}
					$dirforexampleforsources = preg_replace('/__DOL_DATA_ROOT__/', DOL_DATA_ROOT, preg_replace('/\/htdocs\/?$/', '', $tmppackage->srcfile1));
					$dirforexampleforsourcesinstalldir = $dirforexampleforsources.'/htdocs/install/mysql/migration/';
					$filelist = dol_dir_list($dirforexampleforsourcesinstalldir, 'files');
					$laststableupgradeversion = 0;
					foreach ($filelist as $key => $value) {
						$version = explode("-",$value["name"])[1];
						$version = explode(".",$version)[0];
						$laststableupgradeversion = max($laststableupgradeversion,$version);
					}
					$match = '/^'.$laststableupgradeversion.'.*/';
					if (preg_match($match,$lastinstallinstance ) || preg_match($match,$lastupgradelinstance)) {
						$errortab[] = $langs->trans("ErrorAlreadyLastStableVersion");
						$errors++;
					}
				}

				// Search of external modules
				$i=0;
				foreach ($confinstance->global as $key => $val) {
					if (preg_match('/MAIN_MODULES_FOR_EXTERNAL/', $key) && !empty($val)) {
						
						$i++;
					}
				}				
			}else {
				$errortab[] = $langs->trans("NewDbConnexionError");
				$errors ++;
			}
		}
	}else {
		$errortab[] = $langs->trans("InstanceNotFound");
		$errors ++;
	}

}

print '
<div class="page-content-wrapper">
    <div class="page-content">
    <!-- BEGIN PAGE HEADER-->
    <!-- BEGIN PAGE HEAD -->
        <div class="page-head">
        <!-- BEGIN PAGE TITLE -->
            <div class="page-title">
            <h1>'.$langs->trans("Autoupgrade").' <small>'.$langs->trans("AutoupgradeDesc",(!empty(getDolGlobalString("SELLYOURSAAS_LAST_STABLE_VERSION_DOLIBARR"))?"(v".getDolGlobalString("SELLYOURSAAS_LAST_STABLE_VERSION_DOLIBARR").")":"")).'</small></h1>
            </div>
        <!-- END PAGE TITLE -->
        </div>
    <!-- END PAGE HEAD -->
    <!-- END PAGE HEADER-->';

print'
    <div class="page-body">
    <div class="row" id="choosechannel">
    <div class="col-md-12">';
if ($action == "instanceverification") {
	print '<!-- BEGIN STEP3-->
		<div class="portlet light divstep " id="Step3">
		<h2>'.$langs->trans("Step", 3).' - '.$langs->trans("UpgradeVerification").'</small></h2><br>';
		print '<div class="center">';
		print '<h3>'.$langs->trans('UpgradeVerification').' : ';
		if ($errors) {
			print '<span style="color:red">'.$langs->trans('Error').'</span>';
		}else {
			print '<span style="color:green">'.$langs->trans('Success').'</span>';
		}
		print '</h3>';
		print'</div>';
		if ($errors) {
			print '<br><div class="portlet dark" style="width:50%;margin-left:auto;margin-right:auto;">';
			print $langs->trans("ErrorListSupport").' :<br>';
			print '<ul style="list-style-type:\'-\';">';
			foreach ($errortab as $key => $error) {
				print '<li>';
				print $error;
				print '</li>';
			}
			print '</ul></div>';
			print '<div class="center"><a href="'.$backtopagesupport.'"><button type="button" class="btn green-haze btn-circle">'.$langs->trans("CancelUpgradeAndBacktoSupportPage").'</button></a></div>';
		}else {
			print '<form action="'.$_SERVER["PHP_SELF"].'" method="POST">';
			print '<input type="hidden" name="action" value="autoupgrade">';
			print '<input type="hidden" name="mode" value="autoupgrade">';
			print '<input type="hidden" name="backtopagesupport" value="'.$backtopagesupport.'">';
			print '<input type="hidden" name="instanceselect" value="'.GETPOST("instanceselect", "alpha").'">';
			print '<input type="hidden" name="token" value="'.newToken().'">';
			print '<br><h4 class="center">'.$langs->trans("AutoupgradeStep3Text").'</h4>';
			print '<br><div class="containerflexautomigration">
					<div class="right" style="width:30%;margin-right:10px">	
						<button id="" type="submit" class="btn green-haze btn-circle btnstep">'.$langs->trans("ConfirmAutoupgrade").'</button>
					</div>
					<div>
						<a href="'.$backtopagesupport.'"><button type="button" class="btn green-haze btn-circle">'.$langs->trans("CancelUpgradeAndBacktoSupportPage").'</button></a>
					</div>
				</div>';
			print '</form>';
		}
	print '</div>';
	print'</div>';
	print '<!-- END STEP3-->';

} elseif ($action == "autoupgrade") {
	print '<!-- BEGIN STEP4-->';
	print '<div class="portlet light divstep " id="Step4">';
	if ($error) {
		# code...
	}else {
		print '<div class="center">';
		print $langs->trans("AutoupgradeSuccess");
		print '</div">';
	}
	print '</div>';
	print '<!-- END STEP4-->';
} else {
	print '<form action="'.$_SERVER["PHP_SELF"].'#Step'.($stepautoupgrade+1).'" method="GET">';
	print '<input type="hidden" name="backtopagesupport" value="'.$backtopagesupport.'">';
	print '<input type="hidden" name="action" value="'.($stepautoupgrade == 2 ? 'instanceverification' : 'view').'">';
	print '<input type="hidden" name="mode" value="autoupgrade">';
	print '<input type="hidden" name="stepautoupgrade" value="'.($stepautoupgrade+1).'">';
	print '<!-- BEGIN STEP1-->
		<div class="portlet light divstep " id="Step1">
				<h2>'.$langs->trans("Step", 1).' - '.$langs->trans("InstanceConfirmation").'</small></h1><br>
				<div style="padding-left:25px">
				'.$langs->trans("AutoupgradeStep1Text").'<br><br>           
				</div>
				<div class="center" style="padding-top:10px">';
				print '<select id="instanceselect" name="instanceselect" class="minwidth600" required="required">';
				print '<option value="">&nbsp;</option>';
	if (count($listofcontractid) == 0) {
		// Should not happen
	} else {
		$atleastonehigh=0;
		$atleastonefound=0;

		foreach ($listofcontractid as $id => $contract) {
							$planref = $contract->array_options['options_plan'];
							$statuslabel = $contract->array_options['options_deployment_status'];
							$instancename = preg_replace('/\..*$/', '', $contract->ref_customer);

							$dbprefix = $contract->array_options['options_db_prefix'];
							if (empty($dbprefix)) $dbprefix = 'llx_';

			if ($statuslabel == 'undeployed') {
				continue;
			}

							// Get info about PLAN of Contract
							$planlabel = $planref;		// By default but we will take ref and label of service of type 'app' later

							$planid = 0;
							$freeperioddays = 0;
							$directaccess = 0;

							$tmpproduct = new Product($db);
			foreach ($contract->lines as $keyline => $line) {
				if ($line->statut == 5 && $contract->array_options['options_deployment_status'] != 'undeployed') {
									$statuslabel = 'suspended';
				}

				if ($line->fk_product > 0) {
						$tmpproduct->fetch($line->fk_product);
					if ($tmpproduct->array_options['options_app_or_option'] == 'app') {
						$planref = $tmpproduct->ref;			// Warning, ref is in language of user
						$planlabel = $tmpproduct->label;		// Warning, label is in language of user
						$planid = $tmpproduct->id;
						$freeperioddays = $tmpproduct->array_options['options_freeperioddays'];
						$directaccess = $tmpproduct->array_options['options_directaccess'];
						break;
					}
				}
			}

			$ispaid = sellyoursaasIsPaidInstance($contract);

			$color = "green";
			if ($statuslabel == 'processing') { $color = 'orange'; }
			if ($statuslabel == 'suspended') { $color = 'orange'; }
			if ($statuslabel == 'undeployed') { $color = 'grey'; }
			if (preg_match('/^http/i', $contract->array_options['options_suspendmaintenance_message'])) { $color = 'lightgrey'; }

			if ($tmpproduct->array_options['options_typesupport'] != 'none'
				&& !preg_match('/^http/i', $contract->array_options['options_suspendmaintenance_message'])) {
				if (! $ispaid) {	// non paid instances
					$priority = 'low';
					$prioritylabel = '<span class="prioritylow">'.$langs->trans("Priority").' '.$langs->trans("Low").'</span> <span class="opacitymedium">'.$langs->trans("Trial").'</span>';
				} else {
					if ($ispaid) {	// paid with level Premium
						if ($tmpproduct->array_options['options_typesupport'] == 'premium') {
							$priority = 'high';
							$prioritylabel = '<span class="priorityhigh">'.$langs->trans("Priority").' '.$langs->trans("High").'</span>';
							$atleastonehigh++;
						} else {	// paid with level Basic
							$priority = 'medium';
							$prioritylabel = '<span class="prioritymedium">'.$langs->trans("Priority").' '.$langs->trans("Medium").'</span>';
						}
					}
				}

				$optionid = $priority.'_'.$id;
				$labeltoshow = '';
				$labeltoshow .= $langs->trans("Instance").' <strong>'.$contract->ref_customer.'</strong> ';
				//$labeltoshow = $tmpproduct->label.' - '.$contract->ref_customer.' ';
				//$labeltoshow .= $tmpproduct->array_options['options_typesupport'];
				//$labeltoshow .= $tmpproduct->array_options['options_typesupport'];
				$labeltoshow .= ' - ';
				$labeltoshow .= $prioritylabel;

				print '<option value="'.$optionid.'"'.(GETPOST('instanceselect', 'alpha') == $optionid ? ' selected="selected"':'').'" data-html="'.dol_escape_htmltag($labeltoshow).'">';
				print dol_escape_htmltag($labeltoshow);
				print '</option>';
				print ajax_combobox('instanceselect', array(), 0, 0, 'off');

				$atleastonefound++;
			}
		}
	}
		print'</select><br><br>';
		print'</div>
			<div class="center">
			<h3 style="color:red;"><strong>
			'.$langs->trans("AutoupgradeStep1Warning").'
			</strong></h3>
			<h3 style="color:#ffcb00;"><strong>
			'.$langs->trans("AutoupgradeStep1Note").'
			</strong></h3>
			</div><br>
			<div id="buttonstep1upgrade" class="containerflexautomigration" '.(!GETPOST('instanceselect', 'alpha') ?'style="display:none;"':'').'>
					<div class="right" style="width:30%;margin-right:10px">
						<button id="buttonstep_2" type="submit" class="btn green-haze btn-circle btnstep">'.$langs->trans("NextStep").'</button>
					</div>
					<div>
						<a href="'.$backtopagesupport.'"><button type="button" class="btn green-haze btn-circle">'.$langs->trans("CancelUpgradeAndBacktoSupportPage").'</button></a>
					</div>
				</div>
		</div>
		<!-- END STEP1-->';

		print '<!-- BEGIN STEP2-->
			<div id="Step2"></div>
			<div '.($stepautoupgrade <= 1 ? 'style="display:none;"' : '').'class="portlet light divstep" id="step2">
					<h2>'.$langs->trans("Step", 2).' - '.$langs->trans("VersionConfirmation").'</small></h1><br>
					<div>
						'.$langs->trans("AutoupgradeStep2Text",(!empty(getDolGlobalString("SELLYOURSAAS_LAST_STABLE_VERSION_DOLIBARR"))?"(v".getDolGlobalString("SELLYOURSAAS_LAST_STABLE_VERSION_DOLIBARR").")":"")).' 
					</div>
					<br>
					<div class="center">
					<div class="containerflexautomigration">
						<div class="right" style="width:30%;margin-right:10px">	
							<button id="buttonstep_3" type="submit" class="btn green-haze btn-circle btnstep">'.$langs->trans("NextStep").'</button>
						</div>
						<div>
							<a href="'.$backtopagesupport.'"><button type="button" class="btn green-haze btn-circle">'.$langs->trans("CancelUpgradeAndBacktoSupportPage").'</button></a>
						</div>
					</div>
			</div>';
	print'<!-- END STEP2-->';
	print '</form>';
	print '<script>
		jQuery(document).ready(function() {
			$("#instanceselect").on("change",function(){
				if($(this).val() != ""){
					$("#buttonstep1upgrade").show();
				}else{
					$("#buttonstep1upgrade").hide();
				}
			});
		})
	</script>';
}
print "<style>
	* {
		scroll-behavior: smooth !important;
	}
	.topmarginstep{
		margin-top:100px;
	}
	.containerflexautomigration {
		display: flex;
		justify-content:center;
	}
	</style>";
print'</div>
	</div>
	</div>
	</div>
	</div>';
?>
<!-- END PHP TEMPLATE autoupgrade.tpl.php -->