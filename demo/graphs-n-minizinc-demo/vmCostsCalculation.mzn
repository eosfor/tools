enum existingVMs;
enum vmSizes;
enum vmDisks;

array[existingVMs] of int: vmCPU;
array[existingVMs] of int: vmRAM;
array[existingVMs] of int: vmDisk;
array[existingVMs] of int: vmCpuToRamRatio;


array[vmSizes] of int: vmSizeCPU;
array[vmSizes] of float: vmSizeRAM;
array[vmSizes] of float: vmSizePrice;
array[vmSizes] of int: vmSizeACU;
array[vmSizes] of int: vmSizeCpuToRamRatio;

array[vmDisks] of int: vmDiskSizes;
array[vmDisks] of float: vmDiskPrice;

array[existingVMs] of var vmSizes: selectedSize;
array[existingVMs] of var vmDisks: selectedDiskSize;


constraint forall(vm in existingVMs)(
    vmSizeACU[selectedSize[vm]] > 50
);

constraint forall(vm in existingVMs)(
    vmSizeRAM[selectedSize[vm]] >= vmRAM[vm]
);


constraint forall(vm in existingVMs)(
   vmSizeCPU[selectedSize[vm]] >=  vmCPU[vm] * 0.8
);


var float: totalPrice = sum(vm in existingVMs)(vmSizePrice[selectedSize[vm]]);
var int: totalACU = sum(vm in existingVMs)( vmSizeACU[selectedSize[vm]] );
var float: targetFunc = (0.9 * totalPrice) / (0.1 * totalACU);

solve minimize totalPrice;

output [ "\(totalPrice); \(totalACU)\n" ++ join("\n", ["\(vm), \(vmCPU[vm]), \(vmRAM[vm]), " ++ 
                                           "\(vmDisk[vm]), \(selectedSize[vm]), \(vmSizeCPU[selectedSize[vm]]), " ++ 
                                           "\(vmSizeRAM[selectedSize[vm]]), \(vmDiskSizes[selectedDiskSize[vm]]), " ++ 
                                           "\(vmSizePrice[selectedSize[vm]]), \(vmSizeACU[selectedSize[vm]])" | vm in  existingVMs]) ]
