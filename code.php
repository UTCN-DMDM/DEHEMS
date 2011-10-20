<?php
ini_set("precision","20");

$pr=array(
    "indm"=>0.0,
    "u"=>0.0,
    "w1"=>0.0,
    "w2"=>0.0,
    "w3"=>0.0,
    "ta"=>0.0,
    "tav"=>0.0,
    "tae"=>0.0,
    "twe"=>0.0,
    "twev"=>0.0,
    "q_est"=>0.0,
    "q_app"=>0.0,
    "q_ligt"=>0.0,
    "q_occ"=>0.0,
    "q_solar"=>0.0,
    "q_loss"=>0.0,
    "q_other"=>0.0,
    "k_fe"=>0.0,
    "k_oe"=>0.0,
    "k_ie"=>0.0,
    "cae"=>0.0,
    "cwe"=>0.0,
    "tranz"=>0.0,
    "nmem"=>0,
    "n_sim"=>0,
    "t"=>0,
    "umax"=>0.0,
    "umin"=>0.0,
    "k_fe_min"=>0.0,
    "k_oe_min"=>0.0,
    "k_ie_min"=>0.0,
    "cae_min"=>0.0,
    "cwe_min"=>0.0,
    "k_fe_max"=>0.0,
    "k_oe_max"=>0.0,
    "k_ie_max"=>0.0,
    "cae_max"=>0.0,
    "cwe_max"=>0.0,
    "m_abatere"=> array(),
    "y_sim"=> array(),
    "twe_vect"=> array(),
    "tout"=>array(),
    "q"=>array(),
    "m_par"=>array()
);

for($i=0;$i<11;$i++){
    $pr["m_par"][$i]=array(0.0,0.0,0.0,0.0,0.0); 
}

for($i=0;$i<61;$i++){
    $pr["y_sim"][$i]=$pr["twe_vect"][$i]=$pr["tout"][$i]= 0.0; 
}

$fi=$fo='';


function start(){

global $pr,$fi,$fo;

for($i=0;$i<11;$i++){
    $pr["m_abatere"][$i]=1000.4;
}
$fi=fopen("DataInit.txt", "r");
$j=fgets($fi);
$toread=array("indm", "umax", "umin", "nmem", "n_sim","w1","w2","w3", "t", "k_fe", "k_oe", "k_ie","cae", "cwe",
              "k_fe_max", "k_fe_min","k_oe_max", "k_oe_min", "k_ie_max", "k_ie_min","cae_max", "cae_min","cwe_max","cwe_min");
$cnt=0;
while(($buffer = fgetcsv($fi,1000," "))!== false){
foreach($buffer as $k){
    if($k!=''){
       $pr[$toread[$cnt]]=floatval($k);
        $cnt++;
    }
}
}
fclose($fi);
$pr["q_app"]=0;$pr["q_light"]=0;$pr["q_solar"]=0;$pr["q_occ"]=0;$pr["q_loss"]=0;$pr["q_other"]=0;
$fi=fopen("DataIn.txt","r");
$fo=fopen("DataOut.txt","w");
for($i=0;$i<=$j;$i++){
    pas_conducere();
    fwrite($fo,$pr["k_fe"]." ".$pr["k_oe"]." ".$pr["k_ie"]." ".$pr["cae"]." ".$pr["cwe"]." ".$pr["q_est"]." ".$pr["twe"]." ".$pr["tranz"]."\n");
}
fclose($fi);
fclose($fo);
} 

function pas_conducere(){

global $pr,$fi,$fo;

for($i=$pr["nmem"];$i>0;$i--){
    $pr["y_sim"][$i]=$pr["y_sim"][$i-1];
}
list($ci,$cu,$cta)=fscanf($fi,"%f %f %f \n");
$ctout=fgets($fi);
$pr["indm"]=floatval($ci);
$pr["u"]=floatval($cu);
$pr["ta"]=floatval($cta); 
$pr["tout"][0]=floatval($ctout);
StepModel();
for($j=$pr["nmem"];$j>0;$j--){
    $pr["tout"][$j]=$pr["tout"][$j-1];
    $pr["q"][$j]=$pr["q"][$j-1];
}
$pr["q"][0]=$pr["u"]+$pr["q_app"]+$pr["q_light"]+$pr["q_solar"]+$pr["q_occ"]-$pr["q_loss"]+$pr["q_other"];
if($pr["q"][0]<0){
    $pr["q"][0]=0;
}
$pr["y_sim"][0]=$pr["ta"];
} 

function StepModel(){

global $pr;

if(($pr["cae"]>0)and($pr["cwe"]>0)and($pr["indm"]>40)){  Simulare_Model();}
if(($pr["k_fe"]>0)and($pr["cae"]>0)){
    $pr["twe"]=$pr["twev"]+$pr["t"]*($pr["k_ie"]*($pr["tav"]-$pr["twev"])-$pr["k_oe"]*($pr["twev"]-$pr["tout"][1]))/$pr["cwe"];
    $pr["tae"]=$pr["tav"]+$pr["t"]*($pr["q_est"]-$pr["k_ie"]*($pr["tav"]-$pr["twev"])-$pr["k_fe"]*($pr["tav"]-$pr["tout"][1]))/$pr["cae"];
    $pr["q_est"]=($pr["ta"]-$pr["tav"])*$pr["cae"]/$pr["t"]+$pr["k_ie"]*($pr["tav"]-$pr["twe"])+$pr["k_fe"]*($pr["tav"]-$pr["tout"][1]);
    for($i=40;$i>0;$i--){
	    $pr["twe_vect"][$i]=$pr["twe_vect"][$i-1];
    }
    $pr["twe_vect"][0]=$pr["twe"];
    $pr["twev"]=$pr["twe"];
}
$pr["tav"]=$pr["ta"];
}

function Simulare_model(){

global $pr;
for($i=0;$i<11;$i++){
    $m_ab[]=0;
}

$ta_sim[$pr["n_sim"]+1]=$pr["y_sim"][$pr["n_sim"]+1];
$tw_sim[$pr["n_sim"]+1]=$pr["twe_vect"][$pr["n_sim"]];
$abatere=0;
for($i=$pr["n_sim"];$i>0;$i--){
  $ta_sim[$i]=$ta_sim[$i+1]+$pr["t"]*($pr["q"][$i]-$pr["k_ie"]*($ta_sim[$i+1]-$tw_sim[$i+1])-$pr["k_fe"]*($ta_sim[$i+1]-$pr["tout"][$i+1]))/$pr["cae"];
  $tw_sim[$i]=$tw_sim[$i+1]+$pr["t"]*($pr["k_ie"]*($ta_sim[$i+1]-$tw_sim[$i+1])-$pr["k_oe"]*($tw_sim[$i+1]-$pr["tout"][$i+1]))/$pr["cwe"];
  $qqest=($ta_sim[$i]-$ta_sim[$i+1])*$pr["cae"]/$pr["t"]+$pr["k_ie"]*($ta_sim[$i+1]-$tw_sim[$i])+$pr["k_fe"]*($ta_sim[$i+1]-$pr["tout"][$i+1]);
  $abatere=$abatere+(1-$pr["w3"])*abs($ta_sim[$i]-$pr["y_sim"][$i])+ $pr["w3"]*abs($qqest-$pr["q"][$i]);
}
$j1=-1;
for($j=0;$j<11;$j++){
    $m_ab[$j]=0;
    for($i=$pr["n_sim"];$i>0;$i--){
      if($pr["m_par"][$j][3]>0){
        $ta_sim[$i]=$ta_sim[$i+1]+$pr["t"]*($pr["q"][$i]-$pr["m_par"][$j][0]*($ta_sim[$i+1]-$tw_sim[$i+1])-$pr["m_par"][$j][1]*($ta_sim[$i+1]-$pr["tout"][$i+1]))/$pr["m_par"][$j][3]; 
      }
      if($pr["m_par"][$j][4]>0){
        $tw_sim[$i]=$tw_sim[$i+1]+$pr["t"]*($pr["m_par"][$j][0]*($ta_sim[$i+1]-$tw_sim[$i+1])-$pr["m_par"][$j][2]*($tw_sim[$i+1]-$pr["tout"][$i+1]))/$pr["m_par"][$j][4];
      }
      $qqest=($ta_sim[$i]-$ta_sim[$i+1])*$pr["m_par"][$j][3]/$pr["t"]+$pr["m_par"][$j][0]*($ta_sim[$i+1]-$tw_sim[$i])+$pr["m_par"][$j][1]*($ta_sim[$i+1]-$pr["tout"][$i+1]);
      $m_ab[$j]=$m_ab[$j]+(1-$pr["w3"])*abs($ta_sim[$i]-$pr["y_sim"][$i])+ $pr["w3"]*abs($qqest-$pr["q"][$i]);
    }
    if(($m_ab[$j]<$abatere)and($pr["m_par"][$j][3]>0)and($pr["m_par"][$j][4]>0)){
        $abatere=$m_ab[$j];
        $j1=$j;
    }
}
if(($j1>-1)and($pr["tranz"]>0.1)){
  $pr["k_ie"]=$pr["m_par"][$j1][0];
  $pr["k_fe"]=$pr["m_par"][$j1][1];
  $pr["k_oe"]=$pr["m_par"][$j1][2];
  $pr["cae"]= $pr["m_par"][$j1][3];
  $pr["cwe"]= $pr["m_par"][$j1][4];
}
$pr["tranz"]=0; $abatere=1000;  $sumaq=1;
for($i=$pr["n_sim"];$i>1;$i--){
    $pr["tranz"]+=abs($pr["q"][$i]-$pr["q"][$i-1]);
    $sumaq+=$pr["q"][$i];
}
if($sumaq>0){
    $pr["tranz"]=100*$pr["tranz"]/($pr["n_sim"]*$sumaq);
}else{
    $pr["tranz"]=0;
}
if($pr["tranz"]>0.1){
$i10=$i20=$i30=$i40=$i50=0;
$numar=2;
if($pr["tranz"]>0.1){
    for($i1=-$numar;$i1<=$numar;$i1++){
        for($i2=-$numar;$i2<=$numar;$i2++){
            for($i3=-$numar;$i3<=$numar;$i3++){
                for($i4=-$numar;$i4<=$numar;$i4++){   
                    for($i5=-$numar;$i5<=$numar;$i5++){   
                        $abatere1=0;
                        for($i=$pr["n_sim"];$i>0;$i--){ 
                            $ta_sim[$i]=$ta_sim[$i+1]+$pr["t"]*($pr["q"][$i]-$pr["k_ie"]*(1+$i1/$pr["w2"])*($ta_sim[$i+1]-$tw_sim[$i+1])-$pr["k_fe"]*(1+$i2/$pr["w2"])*($ta_sim[$i+1]-$pr["tout"][$i+1]))/($pr["cae"]*(1+$i4/$pr["w2"]));
                            $tw_sim[$i]=$tw_sim[$i+1]+$pr["t"]*($pr["k_ie"]*(1+$i1/$pr["w2"])*($ta_sim[$i+1]-$tw_sim[$i+1])-$pr["k_oe"]*(1+$i3/$pr["w2"])*($tw_sim[$i+1]-$pr["tout"][$i+1]))/($pr["cwe"]*(1+$i5/$pr["w2"]));
                            $qqest=($ta_sim[$i]-$ta_sim[$i+1])*$pr["cae"]*(1+$i4/$pr["w2"])/$pr["t"]+$pr["k_ie"]*(1+$i1/$pr["w2"])*($ta_sim[$i+1]-$tw_sim[$i])+$pr["k_fe"]*(1+$i2/$pr["w2"])*($ta_sim[$i+1]-$pr["tout"][$i+1]);
                            $abatere1=$abatere1+(1-$pr["w3"])*abs($ta_sim[$i]-$pr["y_sim"][$i])+ $pr["w3"]*abs($qqest-$pr["q"][$i]);
                        }
                        if(abs($abatere1)<=abs($abatere)){            
                            $i10=$i1;
                            $i20=$i2;
                            $i30=$i3;
                            $i40=$i4;
                            $i50=$i5;
                            $abatere=$abatere1;
                        }
                    }
                }
            }
        }
    }
}
$pr["k_fe"]=(1-$pr["w1"])*$pr["k_fe"]+$pr["w1"]*$pr["k_fe"]*(1+$i20/$pr["w2"]);
$pr["k_ie"]=(1-$pr["w1"])*$pr["k_ie"]+$pr["w1"]*$pr["k_ie"]*(1+$i10/$pr["w2"]);
$pr["k_oe"]=(1-$pr["w1"])*$pr["k_oe"]+$pr["w1"]*$pr["k_oe"]*(1+$i30/$pr["w2"]); 
$pr["cae"]=(1-$pr["w1"])*$pr["cae"]+$pr["w1"]*$pr["cae"]*(1+$i40/$pr["w2"]);
$pr["cwe"]=(1-$pr["w1"])*$pr["cwe"]+$pr["w1"]*$pr["cwe"]*(1+$i50/$pr["w2"]);
      $test_introducere=1000;
      for($i=0;$i<11;$i++){
         for($j=0;$j<11;$j++){
              $aux=0;
              $aux+=abs($pr["m_par"][$i][0]-$pr["k_ie"])/$pr["k_ie"];
              $aux+=abs($pr["m_par"][$i][1]-$pr["k_fe"])/$pr["k_fe"];
              $aux+=abs($pr["m_par"][$i][2]-$pr["k_oe"])/$pr["k_oe"];
              $aux+=abs($pr["m_par"][$i][3]-$pr["cae"])/$pr["cae"];
              $aux+=abs($pr["m_par"][$i][4]-$pr["cwe"])/$pr["cwe"];
              if($aux<$test_introducere){
                $test_introducere=$aux;
              }
         }
      }
        if($test_introducere>0.001){
          $gasit=false;
          $i=0;
          while(($i<11)and($gasit==false)){
                if($abatere<$pr["m_abatere"][$i]){
                  $gasit=true;
                  $pr["m_par"][$i][0]=$pr["k_ie"];
                  $pr["m_par"][$i][1]= $pr["k_fe"];
                  $pr["m_par"][$i][2]= $pr["k_oe"];
                  $pr["m_par"][$i][3]= $pr["cae"];
                  $pr["m_par"][$i][4]= $pr["cwe"];
                  $pr["m_abatere"][$i]=$abatere;
                }
               $i++;
          }
      }
}
if($pr["cae"]>$pr["cae_max"]){$pr["cae"]=$pr["cae_max"];}
if($pr["cae"]<$pr["cae_min"]){$pr["cae"]=$pr["cae_min"];}
if($pr["cwe"]>$pr["cwe_max"]){$pr["cwe"]=$pr["cwe_max"];}
if($pr["cwe"]<$pr["cwe_min"]){$pr["cwe"]=$pr["cwe_min"];}
if($pr["k_ie"]>$pr["k_ie_max"]){$pr["k_ie"]=$pr["k_ie_max"];}
if($pr["k_ie"]<$pr["k_ie_min"]){$pr["k_ie"]=$pr["k_ie_min"];}
if($pr["k_fe"]>$pr["k_fe_max"]){$pr["k_fe"]=$pr["k_fe_max"];}
if($pr["k_fe"]<$pr["k_fe_min"]){$pr["k_fe"]=$pr["k_fe_min"];}
if($pr["k_oe"]>$pr["k_oe_max"]){$pr["k_oe"]=$pr["k_oe_max"];}
if($pr["k_oe"]<$pr["k_oe_min"]){$pr["k_oe"]=$pr["k_oe_min"];}
} 

start();
?>
