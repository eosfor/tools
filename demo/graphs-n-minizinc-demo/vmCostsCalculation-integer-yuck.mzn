include "yuck.mzn";

% minizinc --solver yuck /problems/vmCostsCalculation-integer-yuck.mzn /problems/vmData-integer-yuck.dzn

enum existingVMs;
enum vmSizes;
enum vmDisks;

array[existingVMs] of int: vmCPU;
array[existingVMs] of int: vmRAM;
array[existingVMs] of int: vmDisk;
array[existingVMs] of int: vmCpuToRamRatio;


array[vmSizes] of int: vmSizeCPU;
array[vmSizes] of int: vmSizeRAM;
array[vmSizes] of int: vmSizePrice;
array[vmSizes] of int: vmSizeACU;
array[vmSizes] of int: vmSizeCpuToRamRatio;

array[vmDisks] of int: vmDiskSizes;
% array[vmDisks] of int: vmDiskPrice;

array[existingVMs] of var vmSizes: selectedSize;
array[existingVMs] of var vmDisks: selectedDiskSize;


constraint forall(vm in existingVMs)(
    vmSizeRAM[selectedSize[vm]] >= vmRAM[vm]
);


constraint forall(vm in existingVMs)(
   vmSizeCPU[selectedSize[vm]] >=  vmCPU[vm] * 0.8
);


var int: totalPrice = sum(vm in existingVMs)(vmSizePrice[selectedSize[vm]]);
var int: totalACU = sum(vm in existingVMs)( vmSizeACU[selectedSize[vm]] );
% var float: targetFunc = (0.9 * totalPrice) / (0.1 * totalACU);

solve :: goal_hierarchy([int_min_goal(totalPrice), int_max_goal(totalACU)]) satisfy;

output [ "\(totalPrice / 10000); \(totalACU)\n" ++ join("\n", ["\(vm), \(vmCPU[vm]), \(vmRAM[vm] / 100), " ++ 
                                           "\(vmDisk[vm]), \(selectedSize[vm]), \(vmSizeCPU[selectedSize[vm]]), " ++ 
                                           "\(vmSizeRAM[selectedSize[vm]] / 100), \(vmDiskSizes[selectedDiskSize[vm]]), " ++ 
                                           "\(vmSizePrice[selectedSize[vm]] / 10000), \(vmSizeACU[selectedSize[vm]])" | vm in  existingVMs]) ]
