CREATE DATABASE paquexpress_db;

USE paquexpress_db;

CREATE TABLE agents (
    emp_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'ID único del empleado/agente (PK)',
    nombre VARCHAR(100) NOT NULL COMMENT 'Nombre completo del agente',
    password_hash VARCHAR(255) NOT NULL COMMENT 'Hash seguro de la contraseña (bcrypt, Argon2)'
);

CREATE TABLE packages (
    paq_id VARCHAR(50) PRIMARY KEY COMMENT 'ID único del paquete/guía (PK)',
    nomb_rec VARCHAR(100) NOT NULL COMMENT 'Nombre del destinatario',
    destino VARCHAR(255) NOT NULL COMMENT 'Dirección física de destino (Requisito clave)',
    estatus ENUM('ASIGNADO', 'EN_TRANSITO', 'ENTREGADO', 'FALLIDO') DEFAULT 'ASIGNADO' COMMENT 'Estatus de seguimiento del paquete',
    assigned_emp_id INT COMMENT 'ID del agente responsable actualmente (FK a agents)',

    FOREIGN KEY (assigned_emp_id) REFERENCES agents(emp_id)
        ON DELETE SET NULL -- Si el agente es eliminado, la asignación se anula (SET NULL)
        ON UPDATE CASCADE -- Si el ID del agente cambia, se actualiza automáticamente aquí
);

CREATE TABLE entregas (
    delivery_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'ID único del registro de entrega (PK)',

    latitude DECIMAL(10,8) NOT NULL COMMENT 'Latitud GPS del momento de la entrega',
    longitude DECIMAL(11,8) NOT NULL COMMENT 'Longitud GPS del momento de la entrega',
    foto_url VARCHAR(255) NOT NULL COMMENT 'URL de la foto de evidencia almacenada en la nube',
    entrega_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha y hora exacta del registro',
    estatus_entrega ENUM('EXITOSA', 'FALLIDA') NOT NULL COMMENT 'Resultado de la entrega',

    paq_id VARCHAR(50) NOT NULL COMMENT 'Paquete al que se refiere la entrega (FK a packages)',
    emp_id INT NOT NULL COMMENT 'Agente que realizó la entrega (FK a agents)',

    FOREIGN KEY (paq_id) REFERENCES packages(paq_id)
        ON DELETE RESTRICT -- No se puede borrar un paquete si tiene registros de entrega asociados
        ON UPDATE C
    FOREIGN KEY (emp_id) REFERENCES agents(emp_id)
        ON DELETE RESTRICT -- No se puede borrar un agente si tiene entregas registradas
        ON UPDATE CASCADE
);

-- Índices adicionales para mejorar el rendimiento de las consultas de trazabilidad
CREATE INDEX idx_paq_status ON packages (estatus);
CREATE INDEX idx_entrega_paq ON entregas (paq_id);
CREATE INDEX idx_entrega_emp ON entregas (emp_id);

INSERT INTO agents (nombre, password_hash) VALUES
('Ian SG', 'es1234');