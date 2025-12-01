import os
import shutil
from typing import Optional, List
from datetime import datetime, timezone
import hashlib # Usaremos MD5 solo por la estructura proporcionada. Se recomienda bcrypt/Argon2.

from fastapi import (
    FastAPI,
    Depends,
    HTTPException,
    UploadFile,
    File,
    Form
)
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import (
    create_engine,
    Column,
    Integer,
    String,
    TIMESTAMP,
    ForeignKey,
    DECIMAL,
    Enum,
    Boolean
)
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship, Session
from pydantic import BaseModel, Field

# Conexión a la base de datos
DATABASE_URL = "mysql+mysqlconnector://root@localhost/paquexpress_db"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()

app = FastAPI()

# Configuración de CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=[""], # Puedes poner "" para permitir todos los orígenes, o una lista específica
    allow_credentials=True,
    allow_methods=["*"], # Permite todos los métodos: GET, POST, PUT, DELETE
    allow_headers=["*"], # Permite todas las cabeceras
)
UPLOAD_DIR = "static/evidence"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# Modelos SQLAlchemy
class Agent(Base):
    _tablename_ = "agents"
    emp_id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), nullable=False)
    password_hash = Column(String(255), nullable=False)
    packages = relationship("Package", back_populates="agent")
    deliveries = relationship("Delivery", back_populates="agent")

class Package(Base):
    _tablename_ = "packages"
    paq_id = Column(String(50), primary_key=True)
    nomb_rec = Column(String(100), nullable=False)
    destino = Column(String(255), nullable=False)
    estatus = Column(Enum('ASIGNADO', 'EN_TRANSITO', 'ENTREGADO', 'FALLIDO'), default='ASIGNADO')
    assigned_emp_id = Column(Integer, ForeignKey("agents.emp_id", ondelete="SET NULL"), nullable=True)
    agent = relationship("Agent", back_populates="packages")
    deliveries = relationship("Delivery", back_populates="package")

class Delivery(Base):
    __tablename__ = "entregas"
    delivery_id = Column(Integer, primary_key=True, index=True)
    # Evidencia y Coordenadas
    latitude = Column(DECIMAL(10, 8), nullable=False)
    longitude = Column(DECIMAL(11, 8), nullable=False)
    foto_url = Column(String(255), nullable=False)
    entrega_timestamp = Column(TIMESTAMP, default=datetime.now(timezone.utc))
    estatus_entrega = Column(Enum('EXITOSA', 'FALLIDA'), nullable=False)

    paq_id = Column(String(50), ForeignKey("packages.paq_id", ondelete="RESTRICT"), nullable=False)
    emp_id = Column(Integer, ForeignKey("agents.emp_id", ondelete="RESTRICT"), nullable=False)
    package = relationship("Package", back_populates="deliveries")
    agent = relationship("Agent", back_populates="deliveries")

Base.metadata.create_all(bind=engine)

# Modelos Pydantic para validación de datos
class AgentBase(BaseModel):
    emp_id: int
    nombre: str

    class Config:
        orm_mode = True

# Nuevo Esquema para el Registro de Agentes
class AgentRegisterModel(BaseModel):
    nombre: str = Field(..., description="Nombre completo del agente")
    password: str = Field(..., description="Contraseña en texto plano")

# Esquema para la respuesta de un Paquete asignado
class PackageResponse(BaseModel):
    paq_id: str
    nomb_rec: str
    destino: str
    estatus: str
    assigned_emp_id: Optional[int]

    class Config:
        orm_mode = True

# Esquema para el Login
class LoginModel(BaseModel):
    emp_id: int = Field(..., description="ID del empleado")
    password: str

# Esquema para el registro de una Entrega (POST)
class DeliveryRegisterModel(BaseModel):
    pass

# Dependencia DB
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Función para encriptar con MD5
def md5_hash(password: str) -> str:
    return hashlib.md5(password.encode('utf-8')).hexdigest()

# Endpoint: Registro de usuario
@app.post("/api/v1/admin/register-agent")
def register_agent(data: AgentRegisterModel, db: Session = Depends(get_db)):

    # 1. Verificar si ya existe un agente con ese nombre
    existing_agent = db.query(Agent).filter(Agent.nombre == data.nombre).first()
    if existing_agent:
        raise HTTPException(
            status_code=400,
            detail="Ya existe un agente registrado con ese nombre."
        )

    # 2. Hashear la contraseña
    hashed_pw = md5_hash(data.password)

    # 3. Crear el nuevo agente
    new_agent = Agent(
        nombre=data.nombre,
        password_hash=hashed_pw
    )

    # 4. Guardar en la base de datos
    db.add(new_agent)
    db.commit()
    db.refresh(new_agent)

    return {
        "msg": "Agente registrado exitosamente",
        "emp_id": new_agent.emp_id,
        "nombre": new_agent.nombre
    }

# Endpoint: Login de agente
@app.post("/api/v1/auth/login", response_model=AgentBase)
def login(data: LoginModel, db: Session = Depends(get_db)):
    hashed_pw = md5_hash(data.password) # Encriptación con MD5
    agent = db.query(Agent).filter(Agent.emp_id == data.emp_id).first()
    if not agent or agent.password_hash != md5_hash(data.password):
        raise HTTPException(status_code=401, detail="Credenciales inválidas")

    return agent

@app.get("/api/v1/packages/assigned/{emp_id}", response_model=List[PackageResponse])
def get_assigned_packages(emp_id: int, db: Session = Depends(get_db)):
    packages = (
        db.query(Package)
        .filter(
            Package.assigned_emp_id == emp_id,
            Package.estatus.in_(['ASIGNADO', 'EN_TRANSITO']) # Paquetes pendientes
        )
        .all()
    )
    if not packages:
        # Se retorna una lista vacía si no hay paquetes
        return []

    return packages

# Endpoint: Registro de Entrega
@app.post("/api/v1/delivery/register")
def register_delivery(
    paq_id: str = Form(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    emp_id: int = Form(...), 
    estatus_entrega: str = Form(..., description="EXITOSA o FALLIDA"),
    photo_file: UploadFile = File(...),
    db: Session = Depends(get_db)
):

    # 1. VERIFICACIÓN DE PAQUETE Y AGENTE
    package = db.query(Package).filter(Package.paq_id == paq_id).first()
    agent = db.query(Agent).filter(Agent.emp_id == emp_id).first()

    if not package or not agent:
        raise HTTPException(status_code=404, detail="Paquete o Agente no encontrado.")
    
    # Generar un nombre único y guardar el archivo en la carpeta local 'static/evidence'
    file_extension = os.path.splitext(photo_file.filename)[1]
    filename = f"{paq_id}_{datetime.now().timestamp()}{file_extension}"
    file_path = os.path.join(UPLOAD_DIR, filename)

    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(photo_file.file, buffer)
        
        # URL ficticia para la base de datos (simulando URL de S3/GCS)
        foto_url = f"/static/evidence/{filename}"

    except Exception as e:
        # Si falla la subida, se cancela la transacción
        raise HTTPException(status_code=500, detail=f"Error al guardar la foto: {str(e)}")

    # 3. EJECUCIÓN TRANSACCIONAL
    try:
        # A. INSERT en la tabla 'entregas'
        delivery_record = Delivery(
            paq_id=paq_id,
            emp_id=emp_id,
            latitude=latitude,
            longitude=longitude,
            foto_url=foto_url,
            estatus_entrega=estatus_entrega.upper()
        )
        db.add(delivery_record)
        
        # B. UPDATE en la tabla 'packages'
        # Solo actualizamos el estatus del paquete si la entrega fue EXITOSA.
        if estatus_entrega.upper() == 'EXITOSA':
            package.estatus = 'ENTREGADO'
        elif estatus_entrega.upper() == 'FALLIDA':
            # Si falla, se puede cambiar a EN_TRANSITO o dejar el ASIGNADO para reintento
            package.estatus = 'FALLIDO'
        
        db.commit()

        return {
            "msg": "Registro de entrega exitoso",
            "delivery_id": delivery_record.delivery_id,
            "foto_url": foto_url
        }

    except Exception as e:
        db.rollback()
        # Eliminar el archivo si la inserción en BD falló
        if os.path.exists(file_path):
            os.remove(file_path)
            
        raise HTTPException(status_code=500, detail=f"Error en la transacción de base de datos: {str(e)}")
    
    
# Endpoint para ver el historial de entregas (Opcional, para la web)
@app.get("/api/v1/delivery/history/{paq_id}")
def get_package_history(paq_id: str, db: Session = Depends(get_db)):

    history = db.query(Delivery).filter(Delivery.paq_id == paq_id).order_by(Delivery.entrega_timestamp.desc()).all()
    
    if not history:
        raise HTTPException(status_code=404, detail="No se encontró historial para este paquete.")

    return history
