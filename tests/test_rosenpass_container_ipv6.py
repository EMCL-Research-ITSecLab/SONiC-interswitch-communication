import subprocess
import docker
import logging

LOGGER = logging.getLogger(__name__)


def setup_module(module):
    # start the containers; Healthcheck in compose file ensures that the containers are ready
    container = subprocess.run(
        ["docker", "compose", "-f", "./docker-compose_ipv6.yaml", "up", "--wait"],
        capture_output=True,
        text=True,
    )


def teardown_module(module):
    # remove all keys created to not confuse them in future tests
    run_docker_command("tests-client-1", "rm -rf /keys/*")
    subprocess.run(["docker", "compose", "down"])


def test_ping_from_client():
    response = run_docker_command("tests-client-1", "ping -I rosenpass0 -c 4 fe70::3")

    LOGGER.info(f"Exit code: {response.exit_code}")
    assert int(response.exit_code) == 0


def run_docker_command(container: str, command: str):
    client = docker.from_env()
    command = command.split()
    return client.containers.get(container).exec_run(command)
