from database import SessionLocal, Base, engine
import models
import auth


Base.metadata.create_all(bind=engine)


permissions_data = [
    ("finance_view", "Permite visualizar financeiro"),
    ("finance_create", "Permite criar lançamentos financeiros"),
    ("finance_edit", "Permite editar lançamentos financeiros"),
    ("finance_delete", "Permite excluir lançamentos financeiros"),

    ("events_view", "Permite visualizar eventos"),
    ("events_create", "Permite criar eventos"),
    ("events_edit", "Permite editar eventos"),
    ("events_delete", "Permite excluir eventos"),

    ("organizations_view", "Permite visualizar organizações"),
    ("organizations_create", "Permite criar organizações"),
    ("organizations_edit", "Permite editar organizações"),
    ("organizations_delete", "Permite excluir organizações"),

    ("users_create", "Permite criar usuários"),
    ("users_view", "Permite visualizar usuários"),
    ("users_edit", "Permite editar usuários"),
    ("users_delete", "Permite excluir usuários"),
    ("users_change_password", "Permite alterar senha de usuários"),

    ("confirmations_create", "Permite confirmar presença em eventos"),
    ("confirmations_view", "Permite visualizar confirmações"),

    ("permissions_view", "Permite visualizar permissões"),
    ("permissions_create", "Permite criar permissões"),
    ("permissions_assign", "Permite vincular permissões a usuários"),
    ("permissions_remove", "Permite remover permissões de usuários"),

    ("dashboard_view", "Permite visualizar o dashboard"),
]


def create_initial_data():
    db = SessionLocal()

    try:
        organization = db.query(models.Organization).filter(
            models.Organization.document == "12345678900000"
        ).first()

        if not organization:
            organization = models.Organization(
                name="Igreja Sede",
                type="igreja",
                document="12345678900000",
                address="Rua Principal, 100",
                city="Curitiba",
                state="PR",
                responsible_name="Ester Souza"
            )

            db.add(organization)
            db.commit()
            db.refresh(organization)

            print("Organização inicial criada.")
        else:
            print("Organização inicial já existe.")

        admin_user = db.query(models.User).filter(
            models.User.email == "admin@email.com"
        ).first()

        if not admin_user:
            admin_user = models.User(
                name="Administrador",
                email="admin@email.com",
                password=auth.hash_password("123456"),
                organization_id=organization.id,
                role="admin"
            )

            db.add(admin_user)
            db.commit()
            db.refresh(admin_user)

            print("Usuário admin criado.")
        else:
            print("Usuário admin já existe.")

        maria_user = db.query(models.User).filter(
            models.User.email == "maria@email.com"
        ).first()

        if not maria_user:
            maria_user = models.User(
                name="Maria",
                email="maria@email.com",
                password=auth.hash_password("123456"),
                organization_id=organization.id,
                role="viewer"
            )

            db.add(maria_user)
            db.commit()
            db.refresh(maria_user)

            print("Usuário Maria criado.")
        else:
            print("Usuário Maria já existe.")

        for permission_name, permission_description in permissions_data:
            permission = db.query(models.Permission).filter(
                models.Permission.name == permission_name
            ).first()

            if not permission:
                permission = models.Permission(
                    name=permission_name,
                    description=permission_description
                )

                db.add(permission)

        db.commit()

        print("Permissões verificadas/criadas.")

        maria_permissions = [
            "organizations_view",
            "events_view",
            "events_create",
            "confirmations_create",
            "confirmations_view",
            "finance_view"
        ]

        for permission_name in maria_permissions:
            permission = db.query(models.Permission).filter(
                models.Permission.name == permission_name
            ).first()

            if permission:
                existing_user_permission = db.query(models.UserPermission).filter(
                    models.UserPermission.user_id == maria_user.id,
                    models.UserPermission.permission_id == permission.id
                ).first()

                if not existing_user_permission:
                    user_permission = models.UserPermission(
                        user_id=maria_user.id,
                        permission_id=permission.id
                    )

                    db.add(user_permission)

        db.commit()

        print("Permissões da Maria verificadas/criadas.")
        print("Dados iniciais criados com sucesso.")

    finally:
        db.close()


if __name__ == "__main__":
    create_initial_data()