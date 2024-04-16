classdef Material
    properties
        n
        m
        K_ref
        T_ref
        C_1
        C_2
        beta
        P_bar
        a_P
        Tr
    end
    methods
        function mat = Material(n, K_ref, T_ref, C_1, C_2, Tr)
            if nargin > 0
                mat.n = n;
                mat.m = n;
                mat.K_ref = K_ref;
                mat.T_ref = T_ref;
                mat.C_1 = C_1;
                mat.C_2 = C_2;
                mat.Tr = Tr;
                mat.a_P = exp(beta * P_bar);
            end
        end

        function a_T = a_T(mat, T)
            a_T = exp(-(mat.C_1 * (T - mat.T_ref)) / (mat.C_2 + (T - mat.T_ref)));
        end

        function K = K(mat, T)
            K = mat.K_ref * (mat.a_T(T))^mat.n * (T / mat.T_ref) * mat.a_P;
        end

        function L = L(mat, T)
            L = mat.Tr * mat.K(T);
        end
    end
end