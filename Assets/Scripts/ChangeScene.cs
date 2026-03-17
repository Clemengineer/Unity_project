using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;
public class ChangeScene : MonoBehaviour
{
   
   
   public void LoadScene()
   {
       SceneManager.LoadScene("Jeux");
   }
}