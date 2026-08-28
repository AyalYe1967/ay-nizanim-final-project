# Nizanim Status-Page - Local Docker Test

This stack runs:

1. Status-Page Django application on http://localhost:8000
2. PostgreSQL 16 with database/user `statuspage`
3. Redis 7, using DB 0 for task queues and DB 1 for caching

## 1. Add the Status-Page source

From this directory run:

    git clone https://github.com/Status-Page/Status-Page.git status-page

If your instructor supplied a Status-Page source folder or zip, use that source instead and
place its contents in the `status-page` directory.

The directory should contain files such as:

    status-page/
      requirements.txt
      upgrade.sh
      contrib/
      statuspage/
        manage.py
        statuspage/
          configuration_example.py

## 2. Start the containers

    docker compose up --build -d

## 3. Check them

    docker compose ps

The expected services are:
- nizanim-status-page
- nizanim-postgres
- nizanim-redis

## 4. Create the Status-Page administrator

    docker compose exec status-page python manage.py createsuperuser

Enter the username and password you want.

## 5. Open Status-Page

Dashboard/login:

    http://localhost:8000/dashboard/

## Useful checks

PostgreSQL:

    docker compose exec postgres psql -U statuspage -d statuspage

Inside psql:

    \conninfo
    \du
    \l
    \q

Redis DB 0 (tasks):

    docker compose exec redis redis-cli -n 0 ping

Redis DB 1 (cache):

    docker compose exec redis redis-cli -n 1 ping

Application logs:

    docker compose logs -f status-page

All logs:

    docker compose logs -f

## Stop

Keep data:

    docker compose down

Delete containers AND local database/Redis volumes:

    docker compose down -v

## Important

This is the local testing stack. It intentionally uses Django's development server on port
8000. For AWS/production, switch the web process to Gunicorn and put Nginx/ALB in front of it,
and run the Status-Page RQ worker/scheduler as separate processes/services.
