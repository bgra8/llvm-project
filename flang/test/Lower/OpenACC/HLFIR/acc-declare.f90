! This test checks lowering of OpenACC declare directive in function and
! subroutine specification parts.

! RUN: bbc -fopenacc -emit-hlfir %s -o - | FileCheck %s

module acc_declare
  contains

  subroutine acc_declare_copy()
    integer :: a(100), i
    !$acc declare copy(a)

    do i = 1, 100
      a(i) = i
    end do
  end subroutine

! CHECK-LABEL: func.func @_QMacc_declarePacc_declare_copy()
! CHECK-DAG: %[[C1:.*]] = arith.constant 1 : index
! CHECK-DAG: %[[ALLOCA:.*]] = fir.alloca !fir.array<100xi32> {bindc_name = "a", uniq_name = "_QMacc_declareFacc_declare_copyEa"}
! CHECK-DAG: %[[DECL:.*]]:2 = hlfir.declare %[[ALLOCA]](%{{.*}}) {acc.declare = #acc.declare<dataClause =  acc_copy>, uniq_name = "_QMacc_declareFacc_declare_copyEa"} : (!fir.ref<!fir.array<100xi32>>, !fir.shape<1>) -> (!fir.ref<!fir.array<100xi32>>, !fir.ref<!fir.array<100xi32>>)
! CHECK: %[[BOUND:.*]] = acc.bounds   lowerbound(%{{.*}} : index) upperbound(%{{.*}} : index) extent(%{{.*}} : index) stride(%[[C1]] : index) startIdx(%[[C1]] : index)
! CHECK: %[[COPYIN:.*]] = acc.copyin varPtr(%[[DECL]]#1 : !fir.ref<!fir.array<100xi32>>) bounds(%[[BOUND]]) -> !fir.ref<!fir.array<100xi32>> {dataClause = #acc<data_clause acc_copy>, name = "a"}
! CHECK: %[[TOKEN:.*]] = acc.declare_enter dataOperands(%[[COPYIN]] : !fir.ref<!fir.array<100xi32>>)
! CHECK: %{{.*}}:2 = fir.do_loop %{{.*}} = %{{.*}} to %{{.*}} step %{{.*}} iter_args(%{{.*}} = %{{.*}}) -> (index, i32) {
! CHECK: }
! CHECK: acc.declare_exit token(%[[TOKEN]]) dataOperands(%[[COPYIN]] : !fir.ref<!fir.array<100xi32>>)
! CHECK: acc.copyout accPtr(%[[COPYIN]] : !fir.ref<!fir.array<100xi32>>) bounds(%[[BOUND]]) to varPtr(%[[DECL]]#1 : !fir.ref<!fir.array<100xi32>>) {dataClause = #acc<data_clause acc_copy>, name = "a"}
! CHECK: return

  subroutine acc_declare_create()
    integer :: a(100), i
    !$acc declare create(a)

    do i = 1, 100
      a(i) = i
    end do
  end subroutine

! CHECK-LABEL: func.func @_QMacc_declarePacc_declare_create() {
! CHECK-DAG: %[[C1:.*]] = arith.constant 1 : index
! CHECK-DAG: %[[ALLOCA:.*]] = fir.alloca !fir.array<100xi32> {bindc_name = "a", uniq_name = "_QMacc_declareFacc_declare_createEa"}
! CHECK-DAG: %[[DECL:.*]]:2 = hlfir.declare %[[ALLOCA]](%{{.*}}) {acc.declare = #acc.declare<dataClause =  acc_create>, uniq_name = "_QMacc_declareFacc_declare_createEa"} : (!fir.ref<!fir.array<100xi32>>, !fir.shape<1>) -> (!fir.ref<!fir.array<100xi32>>, !fir.ref<!fir.array<100xi32>>)
! CHECK: %[[BOUND:.*]] = acc.bounds   lowerbound(%{{.*}} : index) upperbound(%{{.*}} : index) extent(%{{.*}} : index) stride(%[[C1]] : index) startIdx(%[[C1]] : index)
! CHECK: %[[CREATE:.*]] = acc.create varPtr(%[[DECL]]#1 : !fir.ref<!fir.array<100xi32>>)   bounds(%[[BOUND]]) -> !fir.ref<!fir.array<100xi32>> {name = "a"}
! CHECK: %[[TOKEN:.*]] = acc.declare_enter dataOperands(%[[CREATE]] : !fir.ref<!fir.array<100xi32>>)
! CHECK: %{{.*}}:2 = fir.do_loop %{{.*}} = %{{.*}} to %{{.*}} step %{{.*}} iter_args(%{{.*}} = %{{.*}}) -> (index, i32) {
! CHECK: }
! CHECK: acc.declare_exit token(%[[TOKEN]]) dataOperands(%[[CREATE]] : !fir.ref<!fir.array<100xi32>>)
! CHECK: acc.delete accPtr(%[[CREATE]] : !fir.ref<!fir.array<100xi32>>) bounds(%[[BOUND]]) {dataClause = #acc<data_clause acc_create>, name = "a"}
! CHECK: return

  subroutine acc_declare_present(a)
    integer :: a(100), i
    !$acc declare present(a)

    do i = 1, 100
      a(i) = i
    end do
  end subroutine

! CHECK-LABEL: func.func @_QMacc_declarePacc_declare_present(
! CHECK-SAME: %[[ARG0:.*]]: !fir.ref<!fir.array<100xi32>> {fir.bindc_name = "a"})
! CHECK-DAG: %[[C1:.*]] = arith.constant 1 : index
! CHECK-DAG: %[[DECL:.*]]:2 = hlfir.declare %[[ARG0]](%{{.*}}) {acc.declare = #acc.declare<dataClause =  acc_present>, uniq_name = "_QMacc_declareFacc_declare_presentEa"} : (!fir.ref<!fir.array<100xi32>>, !fir.shape<1>) -> (!fir.ref<!fir.array<100xi32>>, !fir.ref<!fir.array<100xi32>>)
! CHECK: %[[BOUND:.*]] = acc.bounds lowerbound(%{{.*}} : index) upperbound(%{{.*}} : index) extent(%{{.*}} : index) stride(%{{.*}} : index) startIdx(%[[C1]] : index)
! CHECK: %[[PRESENT:.*]] = acc.present varPtr(%[[DECL]]#1 : !fir.ref<!fir.array<100xi32>>)   bounds(%[[BOUND]]) -> !fir.ref<!fir.array<100xi32>> {name = "a"}
! CHECK: acc.declare_enter dataOperands(%[[PRESENT]] : !fir.ref<!fir.array<100xi32>>)
! CHECK: %{{.*}}:2 = fir.do_loop %{{.*}} = %{{.*}} to %{{.*}} step %{{.*}} iter_args(%arg{{.*}} = %{{.*}}) -> (index, i32)

  subroutine acc_declare_copyin()
    integer :: a(100), b(10), i
    !$acc declare copyin(a) copyin(readonly: b)

    do i = 1, 100
      a(i) = i
    end do
  end subroutine

! CHECK-LABEL: func.func @_QMacc_declarePacc_declare_copyin()
! CHECK: %[[A:.*]] = fir.alloca !fir.array<100xi32> {bindc_name = "a", uniq_name = "_QMacc_declareFacc_declare_copyinEa"}
! CHECK: %[[ADECL:.*]]:2 = hlfir.declare %[[A]](%{{.*}}) {acc.declare = #acc.declare<dataClause =  acc_copyin>, uniq_name = "_QMacc_declareFacc_declare_copyinEa"} : (!fir.ref<!fir.array<100xi32>>, !fir.shape<1>) -> (!fir.ref<!fir.array<100xi32>>, !fir.ref<!fir.array<100xi32>>)
! CHECK: %[[B:.*]] = fir.alloca !fir.array<10xi32> {bindc_name = "b", uniq_name = "_QMacc_declareFacc_declare_copyinEb"}
! CHECK: %[[BDECL:.*]]:2 = hlfir.declare %[[B]](%{{.*}}) {acc.declare = #acc.declare<dataClause =  acc_copyin_readonly>, uniq_name = "_QMacc_declareFacc_declare_copyinEb"} : (!fir.ref<!fir.array<10xi32>>, !fir.shape<1>) -> (!fir.ref<!fir.array<10xi32>>, !fir.ref<!fir.array<10xi32>>)
! CHECK: %[[BOUND:.*]] = acc.bounds lowerbound(%{{.*}} : index) upperbound(%{{.*}} : index) extent(%{{.*}} : index) stride(%{{.*}} : index) startIdx(%{{.*}} : index)
! CHECK: %[[COPYIN_A:.*]] = acc.copyin varPtr(%[[ADECL]]#1 : !fir.ref<!fir.array<100xi32>>)   bounds(%[[BOUND]]) -> !fir.ref<!fir.array<100xi32>> {name = "a"}
! CHECK: %[[BOUND:.*]] = acc.bounds lowerbound(%{{.*}} : index) upperbound(%{{.*}} : index) extent(%{{.*}} : index) stride(%{{.*}} : index) startIdx(%{{.*}} : index)
! CHECK: %[[COPYIN_B:.*]] = acc.copyin varPtr(%[[BDECL]]#1 : !fir.ref<!fir.array<10xi32>>)   bounds(%[[BOUND]]) -> !fir.ref<!fir.array<10xi32>> {dataClause = #acc<data_clause acc_copyin_readonly>, name = "b"}
! CHECK: acc.declare_enter dataOperands(%[[COPYIN_A]], %[[COPYIN_B]] : !fir.ref<!fir.array<100xi32>>, !fir.ref<!fir.array<10xi32>>)
! CHECK: %{{.*}}:2 = fir.do_loop %{{.*}} = %{{.*}} to %{{.*}} step %{{.*}} iter_args(%arg{{.*}} = %{{.*}}) -> (index, i32)

  subroutine acc_declare_copyout()
    integer :: a(100), i
    !$acc declare copyout(a)

    do i = 1, 100
      a(i) = i
    end do
  end subroutine

! CHECK-LABEL: func.func @_QMacc_declarePacc_declare_copyout()
! CHECK: %[[A:.*]] = fir.alloca !fir.array<100xi32> {bindc_name = "a", uniq_name = "_QMacc_declareFacc_declare_copyoutEa"}
! CHECK: %[[ADECL:.*]]:2 = hlfir.declare %[[A]](%{{.*}}) {acc.declare = #acc.declare<dataClause =  acc_copyout>, uniq_name = "_QMacc_declareFacc_declare_copyoutEa"} : (!fir.ref<!fir.array<100xi32>>, !fir.shape<1>) -> (!fir.ref<!fir.array<100xi32>>, !fir.ref<!fir.array<100xi32>>)
! CHECK: %[[CREATE:.*]] = acc.create varPtr(%[[ADECL]]#1 : !fir.ref<!fir.array<100xi32>>)   bounds(%{{.*}}) -> !fir.ref<!fir.array<100xi32>> {dataClause = #acc<data_clause acc_copyout>, name = "a"}
! CHECK: %[[TOKEN:.*]] = acc.declare_enter dataOperands(%[[CREATE]] : !fir.ref<!fir.array<100xi32>>)
! CHECK: %{{.*}}:2 = fir.do_loop %{{.*}} = %{{.*}} to %{{.*}} step %{{.*}} iter_args(%arg{{.*}} = %{{.*}}) -> (index, i32)
! CHECK: acc.declare_exit token(%[[TOKEN]]) dataOperands(%[[CREATE]] : !fir.ref<!fir.array<100xi32>>)
! CHECK: acc.copyout accPtr(%[[CREATE]] : !fir.ref<!fir.array<100xi32>>)   bounds(%{{.*}}) to varPtr(%[[ADECL]]#1 : !fir.ref<!fir.array<100xi32>>) {name = "a"}
! CHECK: return

  subroutine acc_declare_deviceptr(a)
    integer :: a(100), i
    !$acc declare deviceptr(a)

    do i = 1, 100
      a(i) = i
    end do
  end subroutine

! CHECK-LABEL: func.func @_QMacc_declarePacc_declare_deviceptr(
! CHECK-SAME: %[[ARG0:.*]]: !fir.ref<!fir.array<100xi32>> {fir.bindc_name = "a"}) {
! CHECK: %[[DECL:.*]]:2 = hlfir.declare %[[ARG0]](%{{.*}}) {acc.declare = #acc.declare<dataClause =  acc_deviceptr>, uniq_name = "_QMacc_declareFacc_declare_deviceptrEa"} : (!fir.ref<!fir.array<100xi32>>, !fir.shape<1>) -> (!fir.ref<!fir.array<100xi32>>, !fir.ref<!fir.array<100xi32>>)
! CHECK: %[[DEVICEPTR:.*]] = acc.deviceptr varPtr(%[[DECL]]#1 : !fir.ref<!fir.array<100xi32>>)   bounds(%{{.*}}) -> !fir.ref<!fir.array<100xi32>> {name = "a"}
! CHECK: acc.declare_enter dataOperands(%[[DEVICEPTR]] : !fir.ref<!fir.array<100xi32>>)
! CHECK: %{{.*}}:2 = fir.do_loop %{{.*}} = %{{.*}} to %{{.*}} step %{{.*}} iter_args(%arg{{.*}} = %{{.*}}) -> (index, i32)

  subroutine acc_declare_link(a)
    integer :: a(100), i
    !$acc declare link(a)

    do i = 1, 100
      a(i) = i
    end do
  end subroutine

! CHECK-LABEL: func.func @_QMacc_declarePacc_declare_link(
! CHECK-SAME: %[[ARG0:.*]]: !fir.ref<!fir.array<100xi32>> {fir.bindc_name = "a"})
! CHECK: %[[DECL:.*]]:2 = hlfir.declare %[[ARG0]](%{{.*}}) {acc.declare = #acc.declare<dataClause =  acc_declare_link>, uniq_name = "_QMacc_declareFacc_declare_linkEa"} : (!fir.ref<!fir.array<100xi32>>, !fir.shape<1>) -> (!fir.ref<!fir.array<100xi32>>, !fir.ref<!fir.array<100xi32>>)
! CHECK: %[[LINK:.*]] = acc.declare_link varPtr(%[[DECL]]#1 : !fir.ref<!fir.array<100xi32>>)   bounds(%{{.*}}) -> !fir.ref<!fir.array<100xi32>> {name = "a"}
! CHECK: acc.declare_enter dataOperands(%[[LINK]] : !fir.ref<!fir.array<100xi32>>)
! CHECK: %{{.*}}:2 = fir.do_loop %{{.*}} = %{{.*}} to %{{.*}} step %{{.*}} iter_args(%arg{{.*}} = %{{.*}}) -> (index, i32)

  subroutine acc_declare_device_resident(a)
    integer :: a(100), i
    !$acc declare device_resident(a)

    do i = 1, 100
      a(i) = i
    end do
  end subroutine

! CHECK-LABEL: func.func @_QMacc_declarePacc_declare_device_resident(
! CHECK-SAME: %[[ARG0:.*]]: !fir.ref<!fir.array<100xi32>> {fir.bindc_name = "a"})
! CHECK: %[[DECL:.*]]:2 = hlfir.declare %[[ARG0]](%{{.*}}) {acc.declare = #acc.declare<dataClause =  acc_declare_device_resident>, uniq_name = "_QMacc_declareFacc_declare_device_residentEa"} : (!fir.ref<!fir.array<100xi32>>, !fir.shape<1>) -> (!fir.ref<!fir.array<100xi32>>, !fir.ref<!fir.array<100xi32>>)
! CHECK: %[[DEVICERES:.*]] = acc.declare_device_resident varPtr(%[[DECL]]#1 : !fir.ref<!fir.array<100xi32>>)   bounds(%{{.*}}) -> !fir.ref<!fir.array<100xi32>> {name = "a"}
! CHECK: %[[TOKEN:.*]] = acc.declare_enter dataOperands(%[[DEVICERES]] : !fir.ref<!fir.array<100xi32>>)
! CHECK: %{{.*}}:2 = fir.do_loop %{{.*}} = %{{.*}} to %{{.*}} step %{{.*}} iter_args(%arg{{.*}} = %{{.*}}) -> (index, i32)
! CHECK: acc.declare_exit token(%[[TOKEN]]) dataOperands(%[[DEVICERES]] : !fir.ref<!fir.array<100xi32>>)
! CHECK: acc.delete accPtr(%[[DEVICERES]] : !fir.ref<!fir.array<100xi32>>) bounds(%{{.*}}) {dataClause = #acc<data_clause acc_declare_device_resident>, name = "a"}

  subroutine acc_declare_device_resident2()
    integer, parameter :: n = 100
    real, dimension(n) :: dataparam
    !$acc declare device_resident(dataparam)
  end subroutine

! CHECK-LABEL: func.func @_QMacc_declarePacc_declare_device_resident2()
! CHECK: %[[ALLOCA:.*]] = fir.alloca !fir.array<100xf32> {bindc_name = "dataparam", uniq_name = "_QMacc_declareFacc_declare_device_resident2Edataparam"}
! CHECK: %[[DECL:.*]]:2 = hlfir.declare %[[ALLOCA]](%{{.*}}) {acc.declare = #acc.declare<dataClause =  acc_declare_device_resident>, uniq_name = "_QMacc_declareFacc_declare_device_resident2Edataparam"} : (!fir.ref<!fir.array<100xf32>>, !fir.shape<1>) -> (!fir.ref<!fir.array<100xf32>>, !fir.ref<!fir.array<100xf32>>)
! CHECK: %[[DEVICERES:.*]] = acc.declare_device_resident varPtr(%[[DECL]]#1 : !fir.ref<!fir.array<100xf32>>)   bounds(%{{.*}}) -> !fir.ref<!fir.array<100xf32>> {name = "dataparam"}
! CHECK: %[[TOKEN:.*]] = acc.declare_enter dataOperands(%[[DEVICERES]] : !fir.ref<!fir.array<100xf32>>)
! CHECK: acc.declare_exit token(%[[TOKEN]]) dataOperands(%[[DEVICERES]] : !fir.ref<!fir.array<100xf32>>)
! CHECK: acc.delete accPtr(%[[DEVICERES]] : !fir.ref<!fir.array<100xf32>>) bounds(%{{.*}}) {dataClause = #acc<data_clause acc_declare_device_resident>, name = "dataparam"}

  subroutine acc_declare_link2()
    integer, parameter :: n = 100
    real, dimension(n) :: dataparam
    !$acc declare link(dataparam)
  end subroutine

! CHECK-LABEL: func.func @_QMacc_declarePacc_declare_link2()
! CHECK: %[[ALLOCA:.*]] = fir.alloca !fir.array<100xf32> {bindc_name = "dataparam", uniq_name = "_QMacc_declareFacc_declare_link2Edataparam"}
! CHECK: %[[DECL:.*]]:2 = hlfir.declare %[[ALLOCA]](%{{.*}}) {acc.declare = #acc.declare<dataClause =  acc_declare_link>, uniq_name = "_QMacc_declareFacc_declare_link2Edataparam"} : (!fir.ref<!fir.array<100xf32>>, !fir.shape<1>) -> (!fir.ref<!fir.array<100xf32>>, !fir.ref<!fir.array<100xf32>>)
! CHECK: %[[LINK:.*]] = acc.declare_link varPtr(%[[DECL]]#1 : !fir.ref<!fir.array<100xf32>>)   bounds(%{{.*}}) -> !fir.ref<!fir.array<100xf32>> {name = "dataparam"}
! CHECK: acc.declare_enter dataOperands(%[[LINK]] : !fir.ref<!fir.array<100xf32>>)

  subroutine acc_declare_deviceptr2()
    integer, parameter :: n = 100
    real, dimension(n) :: dataparam
    !$acc declare deviceptr(dataparam)
  end subroutine

! CHECK-LABEL: func.func @_QMacc_declarePacc_declare_deviceptr2()
! CHECK: %[[ALLOCA:.*]] = fir.alloca !fir.array<100xf32> {bindc_name = "dataparam", uniq_name = "_QMacc_declareFacc_declare_deviceptr2Edataparam"}
! CHECK: %[[DECL:.*]]:2 = hlfir.declare %[[ALLOCA]](%{{.*}}) {acc.declare = #acc.declare<dataClause =  acc_deviceptr>, uniq_name = "_QMacc_declareFacc_declare_deviceptr2Edataparam"} : (!fir.ref<!fir.array<100xf32>>, !fir.shape<1>) -> (!fir.ref<!fir.array<100xf32>>, !fir.ref<!fir.array<100xf32>>)
! CHECK: %[[DEVICEPTR:.*]] = acc.deviceptr varPtr(%[[DECL]]#1 : !fir.ref<!fir.array<100xf32>>)   bounds(%{{.*}}) -> !fir.ref<!fir.array<100xf32>> {name = "dataparam"}
! CHECK: acc.declare_enter dataOperands(%[[DEVICEPTR]] : !fir.ref<!fir.array<100xf32>>)

  function acc_declare_in_func()
    real :: a(1024)
    !$acc declare device_resident(a)
  end function

! CHECK-LABEL: func.func @_QMacc_declarePacc_declare_in_func() -> f32 {
! CHECK: %[[DEVICE_RESIDENT:.*]] = acc.declare_device_resident varPtr(%{{.*}}#1 : !fir.ref<!fir.array<1024xf32>>) bounds(%{{.*}}) -> !fir.ref<!fir.array<1024xf32>> {name = "a"}
! CHECK: %[[TOKEN:.*]] = acc.declare_enter dataOperands(%[[DEVICE_RESIDENT]] : !fir.ref<!fir.array<1024xf32>>)
! CHECK: %[[LOAD:.*]] = fir.load %{{.*}}#1 : !fir.ref<f32>
! CHECK: acc.declare_exit token(%[[TOKEN]]) dataOperands(%[[DEVICE_RESIDENT]] : !fir.ref<!fir.array<1024xf32>>)
! CHECK: acc.delete accPtr(%[[DEVICE_RESIDENT]] : !fir.ref<!fir.array<1024xf32>>) bounds(%6) {dataClause = #acc<data_clause acc_declare_device_resident>, name = "a"}
! CHECK: return %[[LOAD]] : f32
! CHECK: }

  function acc_declare_in_func2(i)
    real :: a(1024)
    integer :: i
    !$acc declare create(a)
    return
  end function

! CHECK-LABEL: func.func @_QMacc_declarePacc_declare_in_func2(%arg0: !fir.ref<i32> {fir.bindc_name = "i"}) -> f32 {
! CHECK: %[[ALLOCA_A:.*]] = fir.alloca !fir.array<1024xf32> {bindc_name = "a", uniq_name = "_QMacc_declareFacc_declare_in_func2Ea"}
! CHECK: %[[DECL_A:.*]]:2 = hlfir.declare %[[ALLOCA_A]](%{{.*}}) {acc.declare = #acc.declare<dataClause =  acc_create>, uniq_name = "_QMacc_declareFacc_declare_in_func2Ea"} : (!fir.ref<!fir.array<1024xf32>>, !fir.shape<1>) -> (!fir.ref<!fir.array<1024xf32>>, !fir.ref<!fir.array<1024xf32>>)
! CHECK: %[[CREATE:.*]] = acc.create varPtr(%[[DECL_A]]#1 : !fir.ref<!fir.array<1024xf32>>) bounds(%7) -> !fir.ref<!fir.array<1024xf32>> {name = "a"}
! CHECK: %[[TOKEN:.*]] = acc.declare_enter dataOperands(%[[CREATE]] : !fir.ref<!fir.array<1024xf32>>)
! CHECK:   cf.br ^bb1
! CHECK: ^bb1:
! CHECK: acc.declare_exit token(%[[TOKEN]]) dataOperands(%[[CREATE]] : !fir.ref<!fir.array<1024xf32>>)
! CHECK: acc.delete accPtr(%[[CREATE]] : !fir.ref<!fir.array<1024xf32>>) bounds(%7) {dataClause = #acc<data_clause acc_create>, name = "a"}
! CHECK:   return %{{.*}} : f32
! CHECK: }

end module

module acc_declare_allocatable_test
 integer, allocatable :: data1(:)
 !$acc declare create(data1)
end module

! CHECK-LABEL: acc.global_ctor @_QMacc_declare_allocatable_testEdata1_acc_ctor {
! CHECK:         %[[GLOBAL_ADDR:.*]] = fir.address_of(@_QMacc_declare_allocatable_testEdata1) {acc.declare = #acc.declare<dataClause =  acc_create>} : !fir.ref<!fir.box<!fir.heap<!fir.array<?xi32>>>>
! CHECK:         %[[COPYIN:.*]] = acc.copyin varPtr(%[[GLOBAL_ADDR]] : !fir.ref<!fir.box<!fir.heap<!fir.array<?xi32>>>>)   -> !fir.ref<!fir.box<!fir.heap<!fir.array<?xi32>>>> {dataClause = #acc<data_clause acc_create>, implicit = true, name = "data1", structured = false}
! CHECK:         acc.declare_enter dataOperands(%[[COPYIN]] : !fir.ref<!fir.box<!fir.heap<!fir.array<?xi32>>>>)
! CHECK:         acc.terminator
! CHECK:       }
! CHECK-LABEL: func.func private @_QMacc_declare_allocatable_testEdata1_acc_declare_update_desc_post_alloc() {
! CHECK:         %[[GLOBAL_ADDR:.*]] = fir.address_of(@_QMacc_declare_allocatable_testEdata1) : !fir.ref<!fir.box<!fir.heap<!fir.array<?xi32>>>>
! CHECK:         %[[LOAD:.*]] = fir.load %[[GLOBAL_ADDR]] : !fir.ref<!fir.box<!fir.heap<!fir.array<?xi32>>>>
! CHECK:         %[[BOXADDR:.*]] = fir.box_addr %[[LOAD]] {acc.declare = #acc.declare<dataClause =  acc_create>} : (!fir.box<!fir.heap<!fir.array<?xi32>>>) -> !fir.heap<!fir.array<?xi32>>
! CHECK:         %[[CREATE:.*]] = acc.create varPtr(%[[BOXADDR]] : !fir.heap<!fir.array<?xi32>>) -> !fir.heap<!fir.array<?xi32>> {name = "data1", structured = false}
! CHECK:         acc.declare_enter dataOperands(%[[CREATE]] : !fir.heap<!fir.array<?xi32>>)
! CHECK:         %[[UPDATE:.*]] = acc.update_device varPtr(%[[GLOBAL_ADDR]] : !fir.ref<!fir.box<!fir.heap<!fir.array<?xi32>>>>) -> !fir.ref<!fir.box<!fir.heap<!fir.array<?xi32>>>> {implicit = true, name = "data1_desc", structured = false}
! CHECK:         acc.update dataOperands(%[[UPDATE]] : !fir.ref<!fir.box<!fir.heap<!fir.array<?xi32>>>>)
! CHECK:         return
! CHECK:       }
! CHECK-LABEL: acc.global_dtor @_QMacc_declare_allocatable_testEdata1_acc_dtor {
! CHECK:         %[[GLOBAL_ADDR:.*]] = fir.address_of(@_QMacc_declare_allocatable_testEdata1) {acc.declare = #acc.declare<dataClause =  acc_create>} : !fir.ref<!fir.box<!fir.heap<!fir.array<?xi32>>>>
! CHECK:         %[[DEVICEPTR:.*]] = acc.getdeviceptr varPtr(%[[GLOBAL_ADDR]] : !fir.ref<!fir.box<!fir.heap<!fir.array<?xi32>>>>)   -> !fir.ref<!fir.box<!fir.heap<!fir.array<?xi32>>>> {dataClause = #acc<data_clause acc_create>, name = "data1", structured = false}
! CHECK:         acc.declare_exit dataOperands(%[[DEVICEPTR]] : !fir.ref<!fir.box<!fir.heap<!fir.array<?xi32>>>>)
! CHECK:         acc.delete accPtr(%[[DEVICEPTR]] : !fir.ref<!fir.box<!fir.heap<!fir.array<?xi32>>>>) {dataClause = #acc<data_clause acc_create>, name = "data1", structured = false}
! CHECK:         acc.terminator
! CHECK:       }


module acc_declare_equivalent
  integer, parameter :: n = 10
  real :: v1(n)
  real :: v2(n)
  equivalence(v1(1), v2(1))
  !$acc declare create(v2)
end module

! CHECK-LABEL: acc.global_ctor @_QMacc_declare_equivalentEv2_acc_ctor {
! CHECK:         %[[ADDR:.*]] = fir.address_of(@_QMacc_declare_equivalentEv1) {acc.declare = #acc.declare<dataClause = acc_create>} : !fir.ref<!fir.array<40xi8>>
! CHECK:         %[[CREATE:.*]] = acc.create varPtr(%[[ADDR]] : !fir.ref<!fir.array<40xi8>>) -> !fir.ref<!fir.array<40xi8>> {name = "v2", structured = false}
! CHECK:         acc.declare_enter dataOperands(%[[CREATE]] : !fir.ref<!fir.array<40xi8>>)
! CHECK:         acc.terminator
! CHECK:       }
! CHECK-LABEL: acc.global_dtor @_QMacc_declare_equivalentEv2_acc_dtor {
! CHECK:         %[[ADDR:.*]] = fir.address_of(@_QMacc_declare_equivalentEv1) {acc.declare = #acc.declare<dataClause =  acc_create>} : !fir.ref<!fir.array<40xi8>>
! CHECK:         %[[DEVICEPTR:.*]] = acc.getdeviceptr varPtr(%[[ADDR]] : !fir.ref<!fir.array<40xi8>>) -> !fir.ref<!fir.array<40xi8>> {dataClause = #acc<data_clause acc_create>, name = "v2", structured = false}
! CHECK:         acc.declare_exit dataOperands(%[[DEVICEPTR]] : !fir.ref<!fir.array<40xi8>>)
! CHECK:         acc.delete accPtr(%[[DEVICEPTR]] : !fir.ref<!fir.array<40xi8>>) {dataClause = #acc<data_clause acc_create>, name = "v2", structured = false}
! CHECK:         acc.terminator
! CHECK:       }

module acc_declare_equivalent2
  real :: v1(10)
  real :: v2(5)
  equivalence(v1(6), v2(1))
  !$acc declare create(v2)
end module

! CHECK-LABEL: acc.global_ctor @_QMacc_declare_equivalent2Ev2_acc_ctor {
! CHECK:         %[[ADDR:.*]] = fir.address_of(@_QMacc_declare_equivalent2Ev1) {acc.declare = #acc.declare<dataClause =  acc_create>} : !fir.ref<!fir.array<40xi8>>
! CHECK:         %[[CREATE:.*]] = acc.create varPtr(%[[ADDR]] : !fir.ref<!fir.array<40xi8>>) -> !fir.ref<!fir.array<40xi8>> {name = "v2", structured = false}
! CHECK:         acc.declare_enter dataOperands(%[[CREATE]] : !fir.ref<!fir.array<40xi8>>)
! CHECK:         acc.terminator
! CHECK:       }
! CHECK-LABEL: acc.global_dtor @_QMacc_declare_equivalent2Ev2_acc_dtor {
! CHECK:         %[[ADDR:.*]] = fir.address_of(@_QMacc_declare_equivalent2Ev1) {acc.declare = #acc.declare<dataClause =  acc_create>} : !fir.ref<!fir.array<40xi8>>
! CHECK:         %[[DEVICEPTR:.*]] = acc.getdeviceptr varPtr(%[[ADDR]] : !fir.ref<!fir.array<40xi8>>) -> !fir.ref<!fir.array<40xi8>> {dataClause = #acc<data_clause acc_create>, name = "v2", structured = false}
! CHECK:         acc.declare_exit dataOperands(%[[DEVICEPTR]] : !fir.ref<!fir.array<40xi8>>)
! CHECK:         acc.delete accPtr(%[[DEVICEPTR]] : !fir.ref<!fir.array<40xi8>>) {dataClause = #acc<data_clause acc_create>, name = "v2", structured = false}
! CHECK:         acc.terminator
! CHECK:       }

module acc_declare_allocatable_test2
  integer, allocatable :: data1(:)
  integer, allocatable :: data2(:)
  !$acc declare create(data1, data2, data1)
end module

! CHECK-LABEL: acc.global_ctor @_QMacc_declare_allocatable_test2Edata1_acc_ctor
! CHECK-LABEL: acc.global_ctor @_QMacc_declare_allocatable_test2Edata2_acc_ctor
