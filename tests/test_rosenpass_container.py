import subprocess
import docker


def setup_module(module):
    # start the containers; Healthcheck in compose file ensures that the containers are ready
    subprocess.run(["docker-compose", "up", "--wait"], capture_output=True, text=True)


def teardown_module(module):
    subprocess.run(["docker-compose", "stop"])
    subprocess.run(["docker", "network", "rm", "tests_rosenpass"])
    subprocess.run(["docker-compose", "rm", "-f"])


def test_ping_from_client():
    client = docker.from_env()
    container_name = "tests-client-1"
    command_to_run = ["ping6", "-c", "4", "fe90::3%rosenpass0"]
    response = client.containers.get(container_name).exec_run(command_to_run)

    # Print the result
    print(f"Exit code: {response.exit_code}")
    assert int(response.exit_code) == 0