/* glpmat.h (sparse matrix routines) */

/*----------------------------------------------------------------------
-- Copyright (C) 2000, 2001, 2002, 2003, 2004, 2005 Andrew Makhorin,
-- Department for Applied Informatics, Moscow Aviation Institute,
-- Moscow, Russia. All rights reserved. E-mail: <mao@mai2.rcnet.ru>.
--
-- This file is part of GLPK (GNU Linear Programming Kit).
--
-- GLPK is free software; you can redistribute it and/or modify it
-- under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2, or (at your option)
-- any later version.
--
-- GLPK is distributed in the hope that it will be useful, but WITHOUT
-- ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
-- or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
-- License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with GLPK; see the file COPYING. If not, write to the Free
-- Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
-- 02111-1307, USA.
----------------------------------------------------------------------*/

#ifndef _GLPMAT_H
#define _GLPMAT_H

#define transpose             glp_mat_transpose
#define adat_symbolic         glp_mat_adat_symbolic
#define adat_numeric          glp_mat_adat_numeric
#define min_degree            glp_mat_min_degree
#define chol_symbolic         glp_mat_chol_symbolic
#define chol_numeric          glp_mat_chol_numeric
#define u_solve               glp_mat_u_solve
#define ut_solve              glp_mat_ut_solve

/*----------------------------------------------------------------------
-- STORAGE-BY-ROWS
--
-- For a sparse matrix A, which has m rows, n columns, and ne non-zero
-- elements the storage-by-rows format uses three arrays A_ptr, A_ind,
-- and A_val, which are set up as follows:
--
-- A_ptr is an integer array of length [1+m+1] also called "row pointer
-- array". It contains the relative starting positions of each row of A
-- in the arrays A_ind and A_val, i.e. element A_ptr[i], 1 <= i <= m,
-- indicates where row i begins in the arrays A_ind and A_val. If all
-- elements in row i are zero, then A_ptr[i] = A_ptr[i+1]. Location
-- A_ptr[0] is not used, location A_ptr[1] must contain 1, and location
-- A_ptr[m+1] must contain ne+1 that indicates the position after the
-- last element in the arrays A_ind and A_val.
--
-- A_ind is an integer array of length [1+ne]. Location A_ind[0] is not
-- used, and locations A_ind[1], ..., A_ind[ne] contain column indices
-- of non-zero elements in matrix A.
--
-- A_val is a floating-point array of length [1+ne]. Location A_val[0]
-- is not used, and locations A_val[1], ..., A_val[ne] contain numeric
-- values of non-zero elements in matrix A.
--
-- Non-zero elements of matrix A are stored contiguously, and the rows
-- of matrix A are stored consecutively from 1 to m in the arrays A_ind
-- and A_val. The elements in each row of A may be stored in any order
-- in A_ind and A_val. Note that elements with duplicate column indices
-- are not allowed.
--
-- Let, for example, the following sparse matrix A be given:
--
--    | 11  . 13  .  .  . |
--    | 21 22  . 24  .  . |
--    |  . 32 33  .  .  . |
--    |  .  . 43 44  . 46 |
--    |  .  .  .  .  .  . |
--    | 61 62  .  .  . 66 |
--
-- Then the arrays are:
--
--    A_ptr = { X; 1, 3, 6, 8, 11, 11; 14 }
--
--    A_ind = { X;  1,  3;  4,  2,  1;  2,  3;  4,  3,  6;  1,  2,  6 }
--
--    A_val = { X; 11, 13; 24, 22, 21; 32, 33; 44, 43, 46; 61, 62, 66 }
--
-- Reference:
--
-- Gustavson F.G. Some basic techniques for solving sparse systems of
-- linear equations. In Rose and Willoughby (1972), pp. 41-52.
--
-- PERMUTATION MATRICES
--
-- Let P be a permutation matrix of the order n. It is represented as
-- an integer array P_per of length [1+n+n] as follows: if p[i,j] = 1,
-- then P_per[i] = j and P_per[n+j] = i. Location P_per[0] is not used.
--
-- Let A' = P*A. If i-th row of A corresponds to i'-th row of A', then
-- P_per[i'] = i and P_per[n+i] = i'. */

void transpose(int m, int n, int A_ptr[], int A_ind[], double A_val[],
      int AT_ptr[], int AT_ind[], double AT_val[]);
/* transpose sparse matrix */

int *adat_symbolic(int m, int n, int P_per[], int A_ptr[], int A_ind[],
      int S_ptr[]);
/* compute S = P*A*D*A'*P' (symbolic phase) */

void adat_numeric(int m, int n, int P_per[],
      int A_ptr[], int A_ind[], double A_val[], double D_diag[],
      int S_ptr[], int S_ind[], double S_val[], double S_diag[]);
/* compute S = P*A*D*A'*P' (numeric phase) */

void min_degree(int n, int A_ptr[], int A_ind[], int P_per[]);
/* minimum degree ordering */

int *chol_symbolic(int n, int A_ptr[], int A_ind[], int U_ptr[]);
/* compute Cholesky factorization (symbolic phase) */

int chol_numeric(int n,
      int A_ptr[], int A_ind[], double A_val[], double A_diag[],
      int U_ptr[], int U_ind[], double U_val[], double U_diag[]);
/* compute Cholesky factorization (numeric phase) */

void u_solve(int n, int U_ptr[], int U_ind[], double U_val[],
      double U_diag[], double x[]);
/* solve upper triangular system U*x = b */

void ut_solve(int n, int U_ptr[], int U_ind[], double U_val[],
      double U_diag[], double x[]);
/* solve lower triangular system U'*x = b */

#endif

/* eof */
