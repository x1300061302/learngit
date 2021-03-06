! Copyright (C) 2010-2015 Keith Bennett <K.Bennett@warwick.ac.uk>
! Copyright (C) 2014-2015 Stephan Kuschel <stephan.kuschel@gmail.com>
! Copyright (C) 2009-2010 Chris Brady <C.S.Brady@warwick.ac.uk>
!
! This program is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see <http://www.gnu.org/licenses/>.

MODULE evaluator_blocks

  USE custom_parser
  USE stack
  USE strings

  IMPLICIT NONE

CONTAINS

  SUBROUTINE do_species(opcode, err)

    INTEGER, INTENT(IN) :: opcode
    INTEGER, INTENT(INOUT) :: err

    err = c_err_none
    CALL push_on_eval(REAL(opcode, num))

  END SUBROUTINE do_species



  SUBROUTINE do_operator(opcode, err)

    INTEGER, INTENT(IN) :: opcode
    INTEGER, INTENT(INOUT) :: err
    REAL(num), DIMENSION(2) :: values
    REAL(num) :: val
    LOGICAL :: comp

    err = c_err_none

    IF (opcode == c_opcode_plus) THEN
      CALL get_values(2, values)
      CALL push_on_eval(values(1)+values(2))
      RETURN
    ENDIF

    IF (opcode == c_opcode_minus) THEN
      CALL get_values(2, values)
      CALL push_on_eval(values(1)-values(2))
      RETURN
    ENDIF

    IF (opcode == c_opcode_unary_plus) THEN
      CALL get_values(1, values)
      CALL push_on_eval(values(1))
      RETURN
    ENDIF

    IF (opcode == c_opcode_unary_minus) THEN
      CALL get_values(1, values)
      CALL push_on_eval(-values(1))
      RETURN
    ENDIF

    IF (opcode == c_opcode_times) THEN
      CALL get_values(2, values)
      CALL push_on_eval(values(1)*values(2))
      RETURN
    ENDIF

    IF (opcode == c_opcode_divide) THEN
      CALL get_values(2, values)
#ifdef PARSER_CHECKING
      IF (ABS(values(2)) < c_tiny) THEN
        CALL push_on_eval(0.0_num)
      ELSE
        CALL push_on_eval(values(1)/values(2))
      ENDIF
#else
      CALL push_on_eval(values(1)/values(2))
#endif
      RETURN
    ENDIF

    IF (opcode == c_opcode_power) THEN
      CALL get_values(2, values)
      CALL push_on_eval(values(1)**values(2))
      RETURN
    ENDIF

    IF (opcode == c_opcode_expo) THEN
      CALL get_values(2, values)
      CALL push_on_eval(values(1) * 10.0_num ** values(2))
      RETURN
    ENDIF

    IF (opcode == c_opcode_lt) THEN
      CALL get_values(2, values)
      comp = values(1) < values(2)
      val = 0.0_num
      IF (comp) val = 1.0_num
      CALL push_on_eval(val)
      RETURN
    ENDIF

    IF (opcode == c_opcode_gt) THEN
      CALL get_values(2, values)
      comp = values(1) > values(2)
      val = 0.0_num
      IF (comp) val = 1.0_num
      CALL push_on_eval(val)
      RETURN
    ENDIF

    IF (opcode == c_opcode_eq) THEN
      CALL get_values(2, values)
      comp = (ABS(values(1) - values(2)) <= c_tiny)
      val = 0.0_num
      IF (comp) val = 1.0_num
      CALL push_on_eval(val)
      RETURN
    ENDIF

    IF (opcode == c_opcode_or) THEN
      CALL get_values(2, values)
      comp = (FLOOR(values(1)) /= 0 .OR. FLOOR(values(2)) /= 0)
      val = 0.0_num
      IF (comp)val = 1.0_num
      CALL push_on_eval(val)
      RETURN
    ENDIF

    IF (opcode == c_opcode_and) THEN
      CALL get_values(2, values)
      comp = (FLOOR(values(1)) /= 0 .AND. FLOOR(values(2)) /= 0)
      val = 0.0_num
      IF (comp)val = 1.0_num
      CALL push_on_eval(val)
      RETURN
    ENDIF

    err = c_err_unknown_element

  END SUBROUTINE do_operator



  SUBROUTINE do_constant(opcode, simplify, parameters, err)

    INTEGER, INTENT(IN) :: opcode
    TYPE(parameter_pack), INTENT(IN) :: parameters
    LOGICAL, INTENT(IN) :: simplify
    INTEGER, INTENT(INOUT) :: err
    INTEGER :: err_simplify
    REAL(num) :: val

    err = c_err_none
    err_simplify = c_err_none

    IF (simplify) err_simplify = c_err_other

    IF (opcode == c_const_time) THEN
      CALL push_on_eval(time)
      err = err_simplify
      RETURN
    ENDIF

    IF (opcode == c_const_x) THEN
      IF (parameters%use_grid_position) THEN
        CALL push_on_eval(x(parameters%pack_ix))
      ELSE
        CALL push_on_eval(parameters%pack_pos(1))
      ENDIF
      err = err_simplify
      RETURN
    ENDIF

    IF (opcode == c_const_xb) THEN
      IF (parameters%use_grid_position) THEN
        CALL push_on_eval(xb(parameters%pack_ix))
      ELSE
        CALL push_on_eval(parameters%pack_pos(1))
      ENDIF
      err = err_simplify
      RETURN
    ENDIF

    IF (opcode == c_const_ix) THEN
      CALL push_on_eval(REAL(parameters%pack_ix, num))
      err = err_simplify
      RETURN
    ENDIF

    IF (opcode == c_const_y) THEN
      IF (parameters%use_grid_position) THEN
        CALL push_on_eval(y(parameters%pack_iy))
      ELSE
        CALL push_on_eval(parameters%pack_pos(2))
      ENDIF
      err = err_simplify
      RETURN
    ENDIF

    IF (opcode == c_const_yb) THEN
      IF (parameters%use_grid_position) THEN
        CALL push_on_eval(yb(parameters%pack_iy))
      ELSE
        CALL push_on_eval(parameters%pack_pos(2))
      ENDIF
      err = err_simplify
      RETURN
    ENDIF

    IF (opcode == c_const_iy) THEN
      CALL push_on_eval(REAL(parameters%pack_iy, num))
      err = err_simplify
      RETURN
    ENDIF

    IF (opcode == c_const_z) THEN
      CALL push_on_eval(0.0_num)
      RETURN
    ENDIF

    IF (opcode == c_const_zb) THEN
      CALL push_on_eval(0.0_num)
      RETURN
    ENDIF

    IF (opcode == c_const_iz) THEN
      CALL push_on_eval(1.0_num)
      RETURN
    ENDIF

    IF (opcode == c_const_r_xy) THEN
      IF (parameters%use_grid_position) THEN
        CALL push_on_eval(&
            SQRT(x(parameters%pack_ix)**2 + y(parameters%pack_iy)**2))
      ELSE
        CALL push_on_eval(&
            SQRT(parameters%pack_pos(1)**2 + parameters%pack_pos(2)**2))
      ENDIF
      err = err_simplify
      RETURN
    ENDIF

    IF (opcode == c_const_r_xz) THEN
      IF (parameters%use_grid_position) THEN
        CALL push_on_eval(ABS(x(parameters%pack_ix)))
      ELSE
        CALL push_on_eval(ABS(parameters%pack_pos(1)))
      ENDIF
      err = err_simplify
      RETURN
    ENDIF

    IF (opcode == c_const_r_yz) THEN
      IF (parameters%use_grid_position) THEN
        CALL push_on_eval(ABS(y(parameters%pack_iy)))
      ELSE
        CALL push_on_eval(ABS(parameters%pack_pos(2)))
      ENDIF
      err = err_simplify
      RETURN
    ENDIF

    IF (opcode == c_const_r_xyz) THEN
      IF (parameters%use_grid_position) THEN
        CALL push_on_eval(&
            SQRT(x(parameters%pack_ix)**2 + y(parameters%pack_iy)**2))
      ELSE
        CALL push_on_eval(&
            SQRT(parameters%pack_pos(1)**2 + parameters%pack_pos(2)**2))
      ENDIF
      err = err_simplify
      RETURN
    ENDIF

    IF (opcode >= c_const_custom_lowbound) THEN
      ! Check for custom constants
      val = custom_constant(opcode, parameters, err)
      IF (IAND(err, c_err_unknown_element) == 0) CALL push_on_eval(val)
      err = err_simplify
      RETURN
    ENDIF

    IF (opcode == c_const_pi) THEN
      CALL push_on_eval(pi)
      RETURN
    ENDIF

    IF (opcode == c_const_kb) THEN
      CALL push_on_eval(kb)
      RETURN
    ENDIF

    IF (opcode == c_const_qe) THEN
      CALL push_on_eval(q0)
      RETURN
    ENDIF

    IF (opcode == c_const_c) THEN
      CALL push_on_eval(c)
      RETURN
    ENDIF

    IF (opcode == c_const_me) THEN
      CALL push_on_eval(m0)
      RETURN
    ENDIF

    IF (opcode == c_const_eps0) THEN
      CALL push_on_eval(epsilon0)
      RETURN
    ENDIF

    IF (opcode == c_const_mu0) THEN
      CALL push_on_eval(mu0)
      RETURN
    ENDIF

    IF (opcode == c_const_ev) THEN
      CALL push_on_eval(ev)
      RETURN
    ENDIF

    IF (opcode == c_const_kev) THEN
      CALL push_on_eval(ev*1000.0_num)
      RETURN
    ENDIF

    IF (opcode == c_const_mev) THEN
      CALL push_on_eval(ev*1.0e6_num)
      RETURN
    ENDIF

    IF (opcode == c_const_milli) THEN
      CALL push_on_eval(1.0e-3_num)
      RETURN
    ENDIF

    IF (opcode == c_const_micro) THEN
      CALL push_on_eval(1.0e-6_num)
      RETURN
    ENDIF

    IF (opcode == c_const_nano) THEN
      CALL push_on_eval(1.0e-9_num)
      RETURN
    ENDIF

    IF (opcode == c_const_pico) THEN
      CALL push_on_eval(1.0e-12_num)
      RETURN
    ENDIF

    IF (opcode == c_const_femto) THEN
      CALL push_on_eval(1.0e-15_num)
      RETURN
    ENDIF

    IF (opcode == c_const_atto) THEN
      CALL push_on_eval(1.0e-18_num)
      RETURN
    ENDIF

    IF (opcode == c_const_io_never) THEN
      CALL push_on_eval(REAL(c_io_never, num))
      RETURN
    ENDIF

    IF (opcode == c_const_io_always) THEN
      CALL push_on_eval(REAL(c_io_always, num))
      RETURN
    ENDIF

    IF (opcode == c_const_io_full) THEN
      CALL push_on_eval(REAL(c_io_full, num))
      RETURN
    ENDIF

    IF (opcode == c_const_io_restartable) THEN
      CALL push_on_eval(REAL(c_io_restartable, num))
      RETURN
    ENDIF

    IF (opcode == c_const_io_species) THEN
      CALL push_on_eval(REAL(c_io_species, num))
      RETURN
    ENDIF

    IF (opcode == c_const_io_no_sum) THEN
      CALL push_on_eval(REAL(c_io_no_sum, num))
      RETURN
    ENDIF

    IF (opcode == c_const_io_average) THEN
      CALL push_on_eval(REAL(c_io_averaged, num))
      RETURN
    ENDIF

    IF (opcode == c_const_io_snapshot) THEN
      CALL push_on_eval(REAL(c_io_snapshot, num))
      RETURN
    ENDIF

    IF (opcode == c_const_io_dump_single) THEN
      CALL push_on_eval(REAL(c_io_dump_single, num))
      RETURN
    ENDIF

    IF (opcode == c_const_io_average_single) THEN
      CALL push_on_eval(REAL(c_io_averaged+c_io_average_single, num))
      RETURN
    ENDIF

    IF (opcode == c_const_dir_x) THEN
      CALL push_on_eval(REAL(c_dir_x, num))
      RETURN
    ENDIF

    IF (opcode == c_const_dir_y) THEN
      CALL push_on_eval(REAL(c_dir_y, num))
      RETURN
    ENDIF

    IF (opcode == c_const_dir_px) THEN
      CALL push_on_eval(REAL(c_dir_px, num))
      RETURN
    ENDIF

    IF (opcode == c_const_dir_py) THEN
      CALL push_on_eval(REAL(c_dir_py, num))
      RETURN
    ENDIF

    IF (opcode == c_const_dir_pz) THEN
      CALL push_on_eval(REAL(c_dir_pz, num))
      RETURN
    ENDIF

    IF (opcode == c_const_dir_mod_p) THEN
      CALL push_on_eval(REAL(c_dir_mod_p, num))
      RETURN
    ENDIF

    IF (opcode == c_const_dir_en) THEN
      CALL push_on_eval(REAL(c_dir_en, num))
      RETURN
    ENDIF

    IF (opcode == c_const_dir_gamma_m1) THEN
      CALL push_on_eval(REAL(c_dir_gamma_m1,num))
      RETURN
    ENDIF

    IF (opcode == c_const_dir_xy_angle) THEN
      CALL push_on_eval(REAL(c_dir_xy_angle,num))
      RETURN
    ENDIF

    IF (opcode == c_const_dir_yz_angle) THEN
      CALL push_on_eval(REAL(c_dir_yz_angle,num))
      RETURN
    ENDIF

    IF (opcode == c_const_dir_zx_angle) THEN
      CALL push_on_eval(REAL(c_dir_zx_angle,num))
      RETURN
    ENDIF

    IF (opcode == c_const_nsteps) THEN
      CALL push_on_eval(REAL(nsteps, num))
      RETURN
    ENDIF

    IF (opcode == c_const_t_end) THEN
      CALL push_on_eval(t_end)
      RETURN
    ENDIF

    IF (opcode == c_const_ndims) THEN
      CALL push_on_eval(REAL(c_ndims, num))
      RETURN
    ENDIF

    IF (opcode == c_const_lx) THEN
      CALL push_on_eval(length_x)
      RETURN
    ENDIF

    IF (opcode == c_const_dx) THEN
      CALL push_on_eval(dx)
      RETURN
    ENDIF

    IF (opcode == c_const_x_min) THEN
      CALL push_on_eval(x_min)
      RETURN
    ENDIF

    IF (opcode == c_const_x_max) THEN
      CALL push_on_eval(x_max)
      RETURN
    ENDIF

    IF (opcode == c_const_nx) THEN
      CALL push_on_eval(REAL(nx_global, num))
      RETURN
    ENDIF

    IF (opcode == c_const_nprocx) THEN
      CALL push_on_eval(REAL(nprocx, num))
      RETURN
    ENDIF

    IF (opcode == c_const_ly) THEN
      CALL push_on_eval(length_y)
      RETURN
    ENDIF

    IF (opcode == c_const_dy) THEN
      CALL push_on_eval(dy)
      RETURN
    ENDIF

    IF (opcode == c_const_y_min) THEN
      CALL push_on_eval(y_min)
      RETURN
    ENDIF

    IF (opcode == c_const_y_max) THEN
      CALL push_on_eval(y_max)
      RETURN
    ENDIF

    IF (opcode == c_const_ny) THEN
      CALL push_on_eval(REAL(ny_global, num))
      RETURN
    ENDIF

    IF (opcode == c_const_nprocy) THEN
      CALL push_on_eval(REAL(nprocy, num))
      RETURN
    ENDIF

    ! Ignorable directions

    IF (opcode == c_const_lz) THEN
      CALL push_on_eval(1.0_num)
      RETURN
    ENDIF

    IF (opcode == c_const_dz) THEN
      CALL push_on_eval(1.0_num)
      RETURN
    ENDIF

    IF (opcode == c_const_z_min) THEN
      CALL push_on_eval(-0.5_num)
      RETURN
    ENDIF

    IF (opcode == c_const_z_max) THEN
      CALL push_on_eval(0.5_num)
      RETURN
    ENDIF

    IF (opcode == c_const_nz) THEN
      CALL push_on_eval(1.0_num)
      RETURN
    ENDIF

    IF (opcode == c_const_nprocz) THEN
      CALL push_on_eval(1.0_num)
      RETURN
    ENDIF

    IF (opcode == c_const_maxwell_solver_yee) THEN
      CALL push_on_eval(REAL(c_maxwell_solver_yee, num))
      RETURN
    ENDIF

    IF (opcode == c_const_maxwell_solver_lehe) THEN
      CALL push_on_eval(REAL(c_maxwell_solver_lehe, num))
      RETURN
    ENDIF

    IF (opcode == c_const_maxwell_solver_lehe_x) THEN
      CALL push_on_eval(REAL(c_maxwell_solver_lehe_x, num))
      RETURN
    ENDIF

    IF (opcode == c_const_maxwell_solver_lehe_y) THEN
      CALL push_on_eval(REAL(c_maxwell_solver_lehe_y, num))
      RETURN
    ENDIF

    IF (opcode == c_const_maxwell_solver_lehe_z) THEN
      CALL push_on_eval(REAL(c_maxwell_solver_lehe_z, num))
      RETURN
    ENDIF

    IF (opcode == c_const_maxwell_solver_cowan) THEN
      CALL push_on_eval(REAL(c_maxwell_solver_cowan, num))
      RETURN
    ENDIF

    IF (opcode == c_const_maxwell_solver_pukhov) THEN
      CALL push_on_eval(REAL(c_maxwell_solver_pukhov, num))
      RETURN
    ENDIF

    IF (opcode == c_const_maxwell_solver_custom) THEN
      CALL push_on_eval(REAL(c_maxwell_solver_custom, num))
      RETURN
    ENDIF

    err = c_err_unknown_element

  END SUBROUTINE do_constant



  SUBROUTINE do_functions(opcode, simplify, parameters, err)

    INTEGER, INTENT(IN) :: opcode
    TYPE(parameter_pack), INTENT(IN) :: parameters
    LOGICAL, INTENT(IN) :: simplify
    INTEGER, INTENT(INOUT) :: err
    REAL(num), DIMENSION(4) :: values
    REAL(num) :: val, val_local
    INTEGER :: count, ipoint, ipoint_val, n, err_simplify
    REAL(num), DIMENSION(:), ALLOCATABLE :: var_length_values
    REAL(num) :: point, t0, p0, p1, x0, x1
    INTEGER :: ix, iy, ispec
#include "particle_head.inc"

    err = c_err_none
    err_simplify = c_err_none

    IF (simplify) err_simplify = c_err_other

    IF (opcode == c_func_rho) THEN
      CALL get_values(1, values)
      ispec = NINT(values(1))
      IF (parameters%use_grid_position) THEN
        ix = parameters%pack_ix; iy = parameters%pack_iy
        val_local = species_list(ispec)%initial_conditions%density(ix, iy)
      ELSE
#include "pack_to_grid.inc"
        val_local = 0.0_num
        DO iy = sf_min, sf_max
        DO ix = sf_min, sf_max
          val_local = val_local + gx(ix) * gy(iy) &
              * species_list(ispec)%initial_conditions&
              %density(cell_x+ix, cell_y+iy)
        ENDDO
        ENDDO
      ENDIF
      CALL push_on_eval(val_local)
      err = err_simplify
      RETURN
    ENDIF

    IF (opcode == c_func_tempx) THEN
      CALL get_values(1, values)
      ispec = NINT(values(1))
      IF (parameters%use_grid_position) THEN
        ix = parameters%pack_ix; iy = parameters%pack_iy
        val_local = species_list(ispec)%initial_conditions%temp(ix, iy, 1)
      ELSE
#include "pack_to_grid.inc"
        val_local = 0.0_num
        DO iy = sf_min, sf_max
        DO ix = sf_min, sf_max
          val_local = val_local + gx(ix) * gy(iy) &
              * species_list(ispec)%initial_conditions&
              %temp(cell_x+ix, cell_y+iy, 1)
        ENDDO
        ENDDO
      ENDIF
      CALL push_on_eval(val_local)
      err = err_simplify
      RETURN
    ENDIF

    IF (opcode == c_func_tempy) THEN
      CALL get_values(1, values)
      ispec = NINT(values(1))
      IF (parameters%use_grid_position) THEN
        ix = parameters%pack_ix; iy = parameters%pack_iy
        val_local = species_list(ispec)%initial_conditions%temp(ix, iy, 2)
      ELSE
#include "pack_to_grid.inc"
        val_local = 0.0_num
        DO iy = sf_min, sf_max
        DO ix = sf_min, sf_max
          val_local = val_local + gx(ix) * gy(iy) &
              * species_list(ispec)%initial_conditions&
              %temp(cell_x+ix, cell_y+iy, 2)
        ENDDO
        ENDDO
      ENDIF
      CALL push_on_eval(val_local)
      err = err_simplify
      RETURN
    ENDIF

    IF (opcode == c_func_tempz) THEN
      CALL get_values(1, values)
      ispec = NINT(values(1))
      IF (parameters%use_grid_position) THEN
        ix = parameters%pack_ix; iy = parameters%pack_iy
        val_local = species_list(ispec)%initial_conditions%temp(ix, iy, 3)
      ELSE
#include "pack_to_grid.inc"
        val_local = 0.0_num
        DO iy = sf_min, sf_max
        DO ix = sf_min, sf_max
          val_local = val_local + gx(ix) * gy(iy) &
              * species_list(ispec)%initial_conditions&
              %temp(cell_x+ix, cell_y+iy, 3)
        ENDDO
        ENDDO
      ENDIF
      CALL push_on_eval(val_local)
      err = err_simplify
      RETURN
    ENDIF

    IF (opcode == c_func_tempx_ev) THEN
      CALL get_values(1, values)
      ispec = NINT(values(1))
      IF (parameters%use_grid_position) THEN
        ix = parameters%pack_ix; iy = parameters%pack_iy
        val_local = species_list(ispec)%initial_conditions%temp(ix, iy, 1)
      ELSE
#include "pack_to_grid.inc"
        val_local = 0.0_num
        DO iy = sf_min, sf_max
        DO ix = sf_min, sf_max
          val_local = val_local + gx(ix) * gy(iy) &
              * species_list(ispec)%initial_conditions&
              %temp(cell_x+ix, cell_y+iy, 1)
        ENDDO
        ENDDO
      ENDIF
      CALL push_on_eval(kb / ev * val_local)
      err = err_simplify
      RETURN
    ENDIF

    IF (opcode == c_func_tempy_ev) THEN
      CALL get_values(1, values)
      ispec = NINT(values(1))
      IF (parameters%use_grid_position) THEN
        ix = parameters%pack_ix; iy = parameters%pack_iy
        val_local = species_list(ispec)%initial_conditions%temp(ix, iy, 2)
      ELSE
#include "pack_to_grid.inc"
        val_local = 0.0_num
        DO iy = sf_min, sf_max
        DO ix = sf_min, sf_max
          val_local = val_local + gx(ix) * gy(iy) &
              * species_list(ispec)%initial_conditions&
              %temp(cell_x+ix, cell_y+iy, 2)
        ENDDO
        ENDDO
      ENDIF
      CALL push_on_eval(kb / ev * val_local)
      err = err_simplify
      RETURN
    ENDIF

    IF (opcode == c_func_tempz_ev) THEN
      CALL get_values(1, values)
      ispec = NINT(values(1))
      IF (parameters%use_grid_position) THEN
        ix = parameters%pack_ix; iy = parameters%pack_iy
        val_local = species_list(ispec)%initial_conditions%temp(ix, iy, 3)
      ELSE
#include "pack_to_grid.inc"
        val_local = 0.0_num
        DO iy = sf_min, sf_max
        DO ix = sf_min, sf_max
          val_local = val_local + gx(ix) * gy(iy) &
              * species_list(ispec)%initial_conditions&
              %temp(cell_x+ix, cell_y+iy, 3)
        ENDDO
        ENDDO
      ENDIF
      CALL push_on_eval(kb / ev * val_local)
      err = err_simplify
      RETURN
    ENDIF

    IF (opcode >= c_func_custom_lowbound) THEN
      ! Check for custom functions
      val = custom_function(opcode, parameters, err)
      IF (IAND(err, c_err_unknown_element) == 0) CALL push_on_eval(val)
      err = err_simplify
      RETURN
    ENDIF

    IF (opcode == c_func_floor) THEN
      CALL get_values(1, values)
      CALL push_on_eval(REAL(FLOOR(values(1)),num))
      RETURN
    ENDIF

    IF (opcode == c_func_ceil) THEN
      CALL get_values(1, values)
      CALL push_on_eval(REAL(CEILING(values(1)),num))
      RETURN
    ENDIF

    IF (opcode == c_func_nint) THEN
      CALL get_values(1, values)
      CALL push_on_eval(REAL(NINT(values(1)),num))
      RETURN
    ENDIF

    IF (opcode == c_func_sqrt) THEN
      CALL get_values(1, values)
#ifdef PARSER_CHECKING
      IF (values(1) < 0) THEN
        CALL push_on_eval(0.0_num)
      ELSE
        CALL push_on_eval(SQRT(values(1)))
      ENDIF
#else
      CALL push_on_eval(SQRT(values(1)))
#endif
      RETURN
    ENDIF

    IF (opcode == c_func_sine) THEN
      CALL get_values(1, values)
      CALL push_on_eval(SIN(values(1)))
      RETURN
    ENDIF

    IF (opcode == c_func_cosine) THEN
      CALL get_values(1, values)
      CALL push_on_eval(COS(values(1)))
      RETURN
    ENDIF

    IF (opcode == c_func_tan) THEN
      CALL get_values(1, values)
      CALL push_on_eval(TAN(values(1)))
      RETURN
    ENDIF

    IF (opcode == c_func_exp) THEN
      CALL get_values(1, values)
#ifdef PARSER_CHECKING
      IF (values(1) < c_smallest_exp) THEN
        CALL push_on_eval(0.0_num)
      ELSE
        CALL push_on_eval(EXP(values(1)))
      ENDIF
#else
      CALL push_on_eval(EXP(values(1)))
#endif
      RETURN
    ENDIF

    IF (opcode == c_func_arcsine) THEN
      CALL get_values(1, values)
      CALL push_on_eval(ASIN(values(1)))
      RETURN
    ENDIF

    IF (opcode == c_func_arccosine) THEN
      CALL get_values(1, values)
      CALL push_on_eval(ACOS(values(1)))
      RETURN
    ENDIF

    IF (opcode == c_func_arctan) THEN
      CALL get_values(1, values)
      CALL push_on_eval(ATAN(values(1)))
      RETURN
    ENDIF

    IF (opcode == c_func_neg) THEN
      CALL get_values(1, values)
      CALL push_on_eval(-(values(1)))
      RETURN
    ENDIF

    IF (opcode == c_func_if) THEN
      CALL get_values(3, values)
      IF (FLOOR(values(1)) /= 0) THEN
        val = values(2)
      ELSE
        val = values(3)
      ENDIF
      CALL push_on_eval(val)
      RETURN
    ENDIF

    IF (opcode == c_func_interpolate) THEN
      CALL get_values(1, values)
      count = NINT(values(1))
      ALLOCATE(var_length_values(0:count*2))
      CALL get_values(count*2+1, var_length_values)
      ! Need to account for get_values() split into two calls
      CALL stack_point_fix()
      ! This could be replaced by a bisection algorithm, change at some point
      ! For now, not too bad for small count

      ! var_length_values(0) = position in domain
      point = var_length_values(0)

      p0 = var_length_values(1)
      p1 = var_length_values(count*2-1)

      IF (point < p0) THEN
        ipoint_val = 1
        p1 = var_length_values(3)
        IF (ABS(point - p0) > ABS(p1 - p0)) err = c_err_bad_value
      ELSE IF (point > p1) THEN
        ipoint_val = count - 1
        p0 = var_length_values(count - 3)
        IF (ABS(point - p1) > ABS(p1 - p0)) err = c_err_bad_value
      ELSE
        DO ipoint = 1, count-1
          p0 = var_length_values(ipoint*2-1)
          p1 = var_length_values(ipoint*2+1)
          IF (point >= p0 .AND. point <= p1) THEN
            ipoint_val = ipoint
            EXIT
          ENDIF
        ENDDO
      ENDIF

      IF (err /= c_err_none .AND. rank == 0) THEN
        PRINT'('' WARNING: '', g11.4, &
            & '' not within interpolation range ('', g11.4, '','', g11.4, &
            & '')'')', point, var_length_values(1), var_length_values(count*2-1)
      ENDIF

      err = c_err_none

      p0 = var_length_values(ipoint_val*2-1)
      x0 = var_length_values(ipoint_val*2  )
      p1 = var_length_values(ipoint_val*2+1)
      x1 = var_length_values(ipoint_val*2+2)
      DEALLOCATE(var_length_values)

      val = (point - p0) / (p1 - p0) * (x1 - x0) + x0
      CALL push_on_eval(val)
      RETURN
    ENDIF

    IF (opcode == c_func_tanh) THEN
      CALL get_values(1, values)
      CALL push_on_eval(TANH(values(1)))
      RETURN
    ENDIF

    IF (opcode == c_func_sinh) THEN
      CALL get_values(1, values)
      CALL push_on_eval(SINH(values(1)))
      RETURN
    ENDIF

    IF (opcode == c_func_cosh) THEN
      CALL get_values(1, values)
      CALL push_on_eval(COSH(values(1)))
      RETURN
    ENDIF

    IF (opcode == c_func_ex) THEN
      CALL get_values(c_ndims, values)
      CALL push_on_eval(ex(NINT(values(1)), NINT(values(2))))
      RETURN
    ENDIF

    IF (opcode == c_func_ey) THEN
      CALL get_values(c_ndims, values)
      CALL push_on_eval(ey(NINT(values(1)), NINT(values(2))))
      RETURN
    ENDIF

    IF (opcode == c_func_ez) THEN
      CALL get_values(c_ndims, values)
      CALL push_on_eval(ez(NINT(values(1)), NINT(values(2))))
      RETURN
    ENDIF

    IF (opcode == c_func_bx) THEN
      CALL get_values(c_ndims, values)
      CALL push_on_eval(bx(NINT(values(1)), NINT(values(2))))
      RETURN
    ENDIF

    IF (opcode == c_func_by) THEN
      CALL get_values(c_ndims, values)
      CALL push_on_eval(by(NINT(values(1)), NINT(values(2))))
      RETURN
    ENDIF

    IF (opcode == c_func_bz) THEN
      CALL get_values(c_ndims, values)
      CALL push_on_eval(bz(NINT(values(1)), NINT(values(2))))
      RETURN
    ENDIF

    IF (opcode == c_func_gauss) THEN
      CALL get_values(3, values)
      CALL push_on_eval(EXP(-((values(1)-values(2))/values(3))**2))
      RETURN
    ENDIF

    IF (opcode == c_func_semigauss) THEN
      CALL get_values(4, values)
      ! values are : time, maximum amplitude, amplitude at t = 0,
      ! characteristic time width
      t0 = values(4) * SQRT(-LOG(values(3)/values(2)))
      IF (values(1) <= t0) THEN
        CALL push_on_eval(values(2) * EXP(-((values(1)-t0)/values(4))**2))
      ELSE
        CALL push_on_eval(values(2))
      ENDIF
      RETURN
    ENDIF

    IF (opcode == c_func_supergauss) THEN
      CALL get_values(4, values)
      n = INT(values(4))
      CALL push_on_eval(EXP(-ABS(((values(1)-values(2))/values(3)))**n))
      RETURN
    ENDIF

    IF (opcode == c_func_crit) THEN
      CALL get_values(1, values)
      CALL push_on_eval(values(1)**2 * m0 * epsilon0 / q0**2)
      RETURN
    ENDIF

    IF (opcode == c_func_abs) THEN
      CALL get_values(1, values)
      CALL push_on_eval(ABS(values(1)))
      RETURN
    ENDIF

    IF (opcode == c_func_loge) THEN
      CALL get_values(1, values)
      CALL push_on_eval(LOG(values(1)))
      RETURN
    ENDIF

    IF (opcode == c_func_log10) THEN
      CALL get_values(1, values)
      CALL push_on_eval(LOG10(values(1)))
      RETURN
    ENDIF

    IF (opcode == c_func_log_base) THEN
      CALL get_values(2, values)
      CALL push_on_eval(LOG(values(1))/LOG(values(2)))
      RETURN
    ENDIF

    err = c_err_unknown_element

  END SUBROUTINE do_functions



  SUBROUTINE do_sanity_check(opcode, err)

    INTEGER, INTENT(IN) :: opcode
    INTEGER, INTENT(INOUT) :: err
    REAL(num) :: val
    INTEGER :: stack_point, nargs
    CHARACTER(LEN=64) :: arg1, arg2

    err = c_err_none

    IF (opcode == c_func_interpolate) THEN
      CALL get_stack_point_and_value(stack_point, val)
      nargs = 2 * NINT(val) + 2
      IF (stack_point /= nargs) THEN
        IF (rank == 0) THEN
          CALL integer_as_string(stack_point, arg1)
          CALL integer_as_string(nargs, arg2)
          PRINT*, 'ERROR: Interpolation function has ', TRIM(arg1), &
              ' arguments but should have ', TRIM(arg2)
        ENDIF
        err = c_err_bad_value
      ENDIF
      RETURN
    ENDIF

    err = c_err_unknown_element

  END SUBROUTINE do_sanity_check

END MODULE evaluator_blocks
