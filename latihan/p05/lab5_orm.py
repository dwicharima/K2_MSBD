# Diminta: memetakan Customer dan Rental beserta relasinya menggunakan SQLAlchemy 2.0.
# Dipilih: gaya deklaratif SQLAlchemy 2.0 dengan relationship untuk relasi Customer-Rental.
# Alternatif: menggunakan psycopg dan SQL mentah; tidak dipilih karena soal meminta ORM.

import time

from sqlalchemy import create_engine, ForeignKey, select, func, text
from sqlalchemy.orm import (
    DeclarativeBase,
    Mapped,
    mapped_column,
    relationship,
    Session,
    selectinload,
    joinedload
)


DSN = "postgresql+psycopg://msbd:msbd2026@127.0.0.1:5432/pagila?connect_timeout=5"


class Base(DeclarativeBase):
    pass


class Customer(Base):
    __tablename__ = "customer"
    __table_args__ = {"schema": "public"}

    customer_id: Mapped[int] = mapped_column(primary_key=True)

    rentals: Mapped[list["Rental"]] = relationship(
        back_populates="customer"
    )


class Rental(Base):
    __tablename__ = "rental"
    __table_args__ = {"schema": "public"}

    rental_id: Mapped[int] = mapped_column(primary_key=True)

    customer_id: Mapped[int] = mapped_column(
        ForeignKey("public.customer.customer_id")
    )

    customer: Mapped["Customer"] = relationship(
        back_populates="rentals"
    )


engine = create_engine(DSN, echo=True)


# =========================
# Q17 - N+1 Query
# =========================
def q17_n_plus_one():
    print("\n=== Q17: N+1 Query ===")

    with Session(engine) as session:
        customers = session.scalars(
            select(Customer).limit(10)
        ).all()

        hasil = [
            (c.customer_id, len(c.rentals))
            for c in customers
        ]

        print("Hasil:", hasil)


# =========================
# Q18 - selectinload
# =========================
def q18_selectinload():
    print("\n=== Q18: selectinload ===")

    with Session(engine) as session:
        rows = session.scalars(
            select(Customer)
            .options(selectinload(Customer.rentals))
            .limit(10)
        ).all()

        print("Hasil:", [
            (c.customer_id, len(c.rentals))
            for c in rows
        ])


# =========================
# Q19 - joinedload
# =========================
def q19_joinedload():
    print("\n=== Q19: joinedload ===")

    with Session(engine) as session:
        rows = session.scalars(
            select(Customer)
            .options(joinedload(Customer.rentals))
            .limit(10)
        ).unique().all()

        print("Hasil:", [
            (c.customer_id, len(c.rentals))
            for c in rows
        ])


# =========================
# Q20 - ORM vs SQL Mentah
# =========================
def q20_comparison():
    print("\n=== Q20: ORM dibanding SQL Mentah ===")

    # ORM
    orm_query = (
        select(
            Rental.customer_id,
            func.count(Rental.rental_id).label("jumlah_sewa")
        )
        .group_by(Rental.customer_id)
        .order_by(func.count(Rental.rental_id).desc())
        .limit(5)
    )

    with Session(engine) as session:

        start = time.perf_counter()

        orm_rows = session.execute(orm_query).all()

        orm_time = time.perf_counter() - start

        print("\nHasil ORM:")
        print(orm_rows)
        print(f"Waktu ORM: {orm_time:.6f} detik")

        # SQL Mentah
        raw_query = text("""
            SELECT
                customer_id,
                COUNT(rental_id) AS jumlah_sewa
            FROM public.rental
            GROUP BY customer_id
            ORDER BY jumlah_sewa DESC
            LIMIT 5
        """)

        start = time.perf_counter()

        raw_rows = session.execute(raw_query).all()

        raw_time = time.perf_counter() - start

        print("\nHasil SQL Mentah:")
        print(raw_rows)
        print(f"Waktu SQL mentah: {raw_time:.6f} detik")


if __name__ == "__main__":
    print("Q16: Model Customer dan Rental berhasil dibuat.")

    q17_n_plus_one()
    q18_selectinload()
    q19_joinedload()
    q20_comparison()