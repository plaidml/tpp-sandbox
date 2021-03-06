#map0 = affine_map<(d0, d1, d2) -> (d0, d2)>
#map1 = affine_map<(d0, d1, d2) -> (d2, d1)>
#map2 = affine_map<(d0, d1, d2) -> (d0, d1)>
module {

 func.func @matmultpp(%A: tensor<4x8xf64>, 
          %B: tensor<8x4xf64>, %C: tensor<4x4xf64> {linalg.inplaceable = true}) -> tensor<4x4xf64> {
    %D = linalg.generic {indexing_maps = [#map0, #map1, #map2], 
                         iterator_types = ["parallel", "parallel", "reduction"]} 
    ins(%A, %B: tensor<4x8xf64>, tensor<8x4xf64>) outs(%C: tensor<4x4xf64>) {
      ^bb0(%a: f64, %b: f64, %c: f64):
        %0 = arith.mulf %a, %b : f64
        %1 = arith.addf %c, %0 : f64
        linalg.yield %1 : f64
    } -> tensor<4x4xf64>
    return %D : tensor<4x4xf64>
  }

  func.func @entry() {
    %c0 = arith.constant 0 : index
    %d1 = arith.constant -1.0 : f64

    // Initialize various matrices, dense for stress testing,
    // and sparse to verify correct nonzero structure.
    %da = arith.constant dense<[
        [ 1.1, 2.1, 3.1, 4.1, 5.1, 6.1, 7.1, 8.1 ],
        [ 1.2, 2.2, 3.2, 4.2, 5.2, 6.2, 7.2, 8.2 ],
        [ 1.3, 2.3, 3.3, 4.3, 5.3, 6.3, 7.3, 8.3 ],
        [ 1.4, 2.4, 3.4, 4.4, 5.4, 6.4, 7.4, 8.4 ]
    ]> : tensor<4x8xf64>
    %db = arith.constant dense<[
        [ 10.1, 11.1, 12.1, 13.1 ],
        [ 10.2, 11.2, 12.2, 13.2 ],
        [ 10.3, 11.3, 12.3, 13.3 ],
        [ 10.4, 11.4, 12.4, 13.4 ],
        [ 10.5, 11.5, 12.5, 13.5 ],
        [ 10.6, 11.6, 12.6, 13.6 ],
        [ 10.7, 11.7, 12.7, 13.7 ],
        [ 10.8, 11.8, 12.8, 13.8 ]
    ]> : tensor<8x4xf64>

    // Call kernels with dense.
    %C = arith.constant dense<0.0> : tensor<4x4xf64>
    %0 = call @matmultpp(%da, %db, %C)
       : (tensor<4x8xf64>, tensor<8x4xf64>, tensor<4x4xf64>) -> tensor<4x4xf64>
 
    %m0 = bufferization.to_memref %0 : memref<4x4xf64>
    %v0 = vector.transfer_read %m0[%c0, %c0], %d1 : memref<4x4xf64>, vector<4x4xf64>
    vector.print %v0 : vector<4x4xf64>

    return
  }
}
