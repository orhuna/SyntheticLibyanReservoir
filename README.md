# Synthetic Libyan Reservoir (SLR) Case


## Synposis

Synthetic Libyan Reservoir (SLR) contains a flow simulation deck and associated includes (geological model and a structural grid) for a synthetic analog case to a Libyan onshore oil field. This repository contains all of the geological model  for flow simulation using 3DSL&reg; software of Streamsim&trade;.


## Contents

[Main 3DSL Simulation Deck](/DataFiles/BaseCase.dat) : Main input for flow simulation.

[Porosity and Permeability File](/IncludeFiles/include/depo.GRDECL) : Depositional model containing porosity & permeability 

[3D Structural Grid](IncludeFiles/include/geometry_large.INC) : 3-D Deformational Grid

[Fault Model](IncludeFiles/include/faults_final.INC) : Representation of structural model within the simulation deck

## Components of the Synthethic Case

### Structural Model 

Structural Model consists of 4 faults and 2 deformable horizons. In this case, a brittle deformation is modeled with no smearing. Structural setting in this case consists of 4 normal faults given below:

![alt text](/common/faults.png " Fault Model")

Brittly deformed horizons are given is below:

![alt text](/common/horizons.png " Horizon Model")

### Stratigraphic Model 

Resulting geologic model for the structural model is given below:

![alt text](/common/geo_model.png " Horizon Model")

### Flow Simulation Grid 
Finally the flow model from this geologic model is extracted as below:

![alt text](/common/flow_model.png " Horizon Model")
