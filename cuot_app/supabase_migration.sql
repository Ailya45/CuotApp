-- ============================================================
-- MIGRACIÓN: Módulo de Renovaciones
-- Ejecutar en Supabase SQL Editor (schema: Financiamientos)
-- Compatible con tablas Creditos y Clientes que usan UUID
-- ============================================================

-- 1. Tabla de Renovaciones
CREATE TABLE IF NOT EXISTS "Financiamientos"."Renovaciones" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    credito_original_id UUID NOT NULL REFERENCES "Financiamientos"."Creditos"(id) ON DELETE CASCADE,
    credito_nuevo_id UUID REFERENCES "Financiamientos"."Creditos"(id) ON DELETE SET NULL,
    cliente_id UUID NOT NULL REFERENCES "Financiamientos"."Clientes"(id) ON DELETE CASCADE,
    motivo TEXT,
    condiciones_anteriores JSONB DEFAULT '{}'::jsonb,
    condiciones_nuevas JSONB DEFAULT '{}'::jsonb,
    nuevo_plazo INT,
    unidad_plazo TEXT DEFAULT 'meses',
    nueva_tasa_interes NUMERIC(5,2) DEFAULT 0,
    nuevo_monto_cuota NUMERIC(12,2) DEFAULT 0,
    monto_abono NUMERIC(12,2) DEFAULT 0,
    incluir_mora BOOLEAN DEFAULT false,
    monto_mora NUMERIC(12,2) DEFAULT 0,
    fecha_renovacion TIMESTAMPTZ DEFAULT NOW(),
    usuario_autoriza TEXT,
    estado TEXT DEFAULT 'solicitada' CHECK (estado IN ('solicitada','aprobada','rechazada','cancelada')),
    observaciones TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Tabla de Historial de Renovaciones (auditoría)
CREATE TABLE IF NOT EXISTS "Financiamientos"."Historial_Renovaciones" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    renovacion_id UUID NOT NULL REFERENCES "Financiamientos"."Renovaciones"(id) ON DELETE CASCADE,
    estado_anterior TEXT,
    estado_nuevo TEXT NOT NULL,
    fecha_cambio TIMESTAMPTZ DEFAULT NOW(),
    usuario_id TEXT,
    observaciones TEXT
);

-- 3. Índices para rendimiento
CREATE INDEX IF NOT EXISTS idx_renovaciones_credito_original 
    ON "Financiamientos"."Renovaciones"(credito_original_id);
CREATE INDEX IF NOT EXISTS idx_renovaciones_cliente 
    ON "Financiamientos"."Renovaciones"(cliente_id);
CREATE INDEX IF NOT EXISTS idx_renovaciones_estado 
    ON "Financiamientos"."Renovaciones"(estado);
CREATE INDEX IF NOT EXISTS idx_historial_renovaciones_renovacion 
    ON "Financiamientos"."Historial_Renovaciones"(renovacion_id);

-- 4. Habilitar RLS (Row Level Security)
ALTER TABLE "Financiamientos"."Renovaciones" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Financiamientos"."Historial_Renovaciones" ENABLE ROW LEVEL SECURITY;

-- Política permisiva para desarrollo (ajustar en producción)
CREATE POLICY "Allow all for Renovaciones" ON "Financiamientos"."Renovaciones"
    FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for Historial_Renovaciones" ON "Financiamientos"."Historial_Renovaciones"
    FOR ALL USING (true) WITH CHECK (true);
