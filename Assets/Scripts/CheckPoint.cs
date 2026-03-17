using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CheckPoint : MonoBehaviour
{
    [SerializeField] List<GameObject> checkPoints;
    [SerializeField] GameObject player;
    [SerializeField] Vector3 vectorPoint;
    [SerializeField] float dead;
    

    // Update is called once per frame
    void Update()
    {
        if (player.transform.position.y < dead)
        {
            player.transform.position = vectorPoint;

            Debug.Log(player.transform.position.y + "  et  dead =" + dead);
        }
    }
    private void OnTriggerEnter(Collider other)
    {
        vectorPoint = player.transform.position;
        Destroy(other.gameObject);
    }
}
